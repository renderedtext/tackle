require "spec_helper"

describe "Healthy Consumers" do
  before(:all) do
    @messages = []

    @tackle_options = {
      :url => "amqp://localhost",
      :exchange => "test-exchange",
      :routing_key => "test-key",
      :service => "test-service",
      :retry_delay => 1,
      :retry_limit => 3
    }

    Thread.new do
      Tackle.consume(@tackle_options) do |message|
        @messages << message
      end
    end

    sleep 2

    Tackle.publish("Hi!", @tackle_options)

    sleep 2
  end

  describe "message consumption" do
    it "doesn't raise any exception" do
      expect(@exceptions).to be_empty
    end

    it "consumes the message" do
      expect(@messages).to eq(["Hi!"])
    end

    it "leaves the dead queue empty" do
      dead_queue = "test-service.test-key.dead"

      expect(BunnyHelper.message_count(dead_queue)).to be(0)
    end
  end
end
