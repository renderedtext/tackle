require "spec_helper"

describe "Manual Ack Mode" do
  before(:all) do
    @messages = []

    @tackle_options = {
      :url => "amqp://localhost",
      :exchange => "test-exchange",
      :routing_key => "test-key",
      :service => "manual-acking-service",
      :retry_delay => 1,
      :retry_limit => 3,
      :manual_ack => true
    }

    @worker = Thread.new do
      Tackle.consume(@tackle_options) do |message|
        # accept only positive numbers

        @messages << message

        if message["value"].to_i.even?
          Tackle::ACK
        else
          Tackle::NACK
        end
      end
    end

    sleep 2
  end

  after(:all) do
    @worker.kill
  end

  describe "acked messages" do
    before(:all) do
      @messages = []

      Tackle.publish("2", @tackle_options) # will be processed

      sleep 5
    end

    it "processes the message only once" do
      expect(@messages).to eq(["2"])
    end

    it "cleares the queue" do
      expect(BunnyHelper.message_count("manual-acking-service.test-key")).to be(0)
    end

    it "leaves the dead queue empty" do
      expect(BunnyHelper.message_count("manual-acking-service.test-key.dead")).to be(0)
    end
  end

  describe "nacked messages" do
    before(:all) do
      @messages = []

      Tackle.publish("3", @tackle_options) # will be processed

      sleep 5
    end

    it "processes the message multiple times" do
      expect(@messages).to eq(["3", "3", "3", "3"])
    end

    it "cleares the queue" do
      expect(BunnyHelper.message_count("manual-acking-service.test-key")).to be(0)
    end

    it "leaves the message in the dead queue" do
      expect(BunnyHelper.message_count("manual-acking-service.test-key.dead")).to be(1)
    end
  end
end
