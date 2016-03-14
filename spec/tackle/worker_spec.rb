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

  def send_message
    channel = conn.create_channel
    x = channel.fanout("test-exchange")
    x.publish "x"
  end

  before do
    logger = Logger.new(STDOUT)
    @worker = Tackle::Worker.new(:url => "localhost",
                                 :exchange => "test-exchange",
                                 :queue => "test-queue",
                                 :retry_limit => 2,
                                 :logger => logger)
    @worker.connect
  end

  describe "#process_message" do
    context "without exceptions" do

      it "processes message without retries" do
        send_message
        sleep(1)
        delivery_info, properties, payload = @worker.rabbit.queue.pop
        execution_queue = []
        processor = lambda { |body| execution_queue << body * 2 }

        @worker.process_message(delivery_info, properties, payload, processor)

        expect(execution_queue).to eql(["xx"])
      end

    end

    context "with exceptions" do

      it "tries to process message, sends message to DLQ and gets it back to source queue" do
        @worker.rabbit.queue.purge
        send_message
        sleep(2)
        expect(@worker.rabbit.queue.message_count).to eql(1)

        delivery_info, properties, payload = @worker.rabbit.queue.pop
        execution_queue = []
        processor = Proc.new { |body| execution_queue << body * 2; raise Exception }

        @worker.process_message(delivery_info, properties, payload, processor)
        expect(execution_queue).to eql(["xx"])

        @worker.connect
        expect(@worker.rabbit.queue.message_count).to eql(0)

        sleep(1)
        expect(@worker.rabbit.dead_letter_queue.message_count).to eql(1)

        sleep(5)
        expect(@worker.rabbit.dead_letter_queue.message_count).to eql(0)
        expect(@worker.rabbit.queue.message_count).to eql(1)
      end

    end
  end

end
