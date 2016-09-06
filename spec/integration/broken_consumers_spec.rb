require "spec_helper"

describe "Broken Consumers" do
  before(:all) do
    @messages = []
    @timestamps = []

    @tackle_options = {
      :url => "amqp://localhost",
      :exchange => "test-exchange",
      :routing_key => "test-key",
      :service => "broken-service",
      :retry_delay => 1,
      :retry_limit => 3
    }

    @worker = Thread.new do
      Tackle.consume(@tackle_options) do |message|
        @messages << message
        @timestamps << Time.now
        raise "Test exception"
      end
    end

    sleep 2

    Tackle.publish("Hi!", @tackle_options)

    sleep 5
  end

  after(:all) do
    @worker.kill
  end

  describe "message consumption" do
    it "receives the message multiple times" do
      # receives once, and retries 3 times
      expect(@messages).to eq(["Hi!", "Hi!", "Hi!", "Hi!"])
    end

    it "pushes the message to the dead queue" do
      dead_queue = "broken-service.test-key.dead"

      expect(BunnyHelper.message_count(dead_queue)).to be > 0
    end

    it "clears the queue from messages" do
      dead_queue = "broken-service.test-key"

      expect(BunnyHelper.message_count(dead_queue)).to eq(0)
    end

    it "waits 'retry_delay' between each retry" do
      expect(@timestamps[1] - @timestamps[0]).to be_within(0.5).of(1)
      expect(@timestamps[2] - @timestamps[1]).to be_within(0.5).of(1)
      expect(@timestamps[3] - @timestamps[2]).to be_within(0.5).of(1)
    end
  end
end
