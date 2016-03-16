require 'spec_helper'

describe Tackle::Worker do

  let(:conn) do
    conn = Bunny.new
    conn.start
    conn
  end

  after :each do
    conn.close if conn.open?
  end

  def send_message(message)
    channel = conn.create_channel
    x = channel.fanout("test-exchange")
    x.publish message, :routing_key => "test-routing-key"
  end

  before do
    logger = Logger.new(STDOUT)
    @worker = Tackle::Worker.new("test-exchange", "test-routing-key", "test-queue", :retry_limit => 2,
                                                                                    :retry_delay => 5)
  end

  describe "#process_message" do
    context "without exceptions" do

      it "processes message without retries" do
        @worker.rabbit.queue.purge
        send_message("ab")
        sleep(1)
        delivery_info, properties, payload = @worker.rabbit.queue.pop
        execution_queue = []
        processor = lambda { |body| execution_queue << body * 2 }

        @worker.process_message(delivery_info, properties, payload, processor)

        expect(execution_queue).to eql(["abab"])
      end

    end

    context "with exceptions" do

      it "tries to process message, sends message to DLQ and gets it back to source queue" do
        @worker.rabbit.queue.purge
        send_message("x")
        sleep(2)
        expect(@worker.rabbit.queue.message_count).to eql(1)

        delivery_info, properties, payload = @worker.rabbit.queue.pop(:manual_ack => true)
        execution_queue = []
        processor = Proc.new { |body| execution_queue << body + "0"; raise Exception }

        @worker.process_message(delivery_info, properties, payload, processor)
        expect(execution_queue).to eql(["x0"])

        expect(@worker.rabbit.queue.message_count).to eql(0)

        sleep(1)
        # Message is added to dead letter queue
        expect(@worker.rabbit.dead_letter_queue.message_count).to eql(1)

        sleep(5)
        # Once dead letter queue TTL expires message is pushed back to source queue
        expect(@worker.rabbit.dead_letter_queue.message_count).to eql(0)
        expect(@worker.rabbit.queue.message_count).to eql(1)
      end

      it "tries to reprocess the message twice and gives up" do
        @worker.rabbit.queue.purge
        send_message("x")
        sleep(2)
        expect(@worker.rabbit.queue.message_count).to eql(1)

        execution_queue = []
        processor = Proc.new { |body| execution_queue << body + "1"; raise Exception }

        delivery_info, properties, payload = @worker.rabbit.queue.pop(:manual_ack => true)
        @worker.process_message(delivery_info, properties, payload, processor)
        expect(execution_queue).to eql(["x1"])

        sleep(6)

        # First retry
        delivery_info, properties, payload = @worker.rabbit.queue.pop(:manual_ack => true)
        @worker.process_message(delivery_info, properties, payload, processor)
        expect(execution_queue).to eql(["x1", "x1"])

        sleep(6)

        # Second retry
        delivery_info, properties, payload = @worker.rabbit.queue.pop(:manual_ack => true)
        @worker.process_message(delivery_info, properties, payload, processor)
        expect(execution_queue).to eql(["x1", "x1", "x1"])

        sleep(1)

        # Message is discarded
        expect(@worker.rabbit.dead_letter_queue.message_count).to eql(0)
        expect(@worker.rabbit.queue.message_count).to eql(0)
      end

    end
  end

end
