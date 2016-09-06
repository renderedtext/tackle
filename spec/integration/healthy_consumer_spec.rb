require "spec_helper"

describe "Healthy Consumers" do
  before(:all) do
    @messages = []

    @tackle_options = {
      :url => "amqp://localhost",
      :exchange => "test-exchange",
      :routing_key => "test-key",
      :service => "healthy-service",
      :retry_delay => 1,
      :retry_limit => 3
    }

    @worker = Thread.new do
      Tackle.consume(@tackle_options) do |message|
        @messages << message
      end
    end

    sleep 2

    Tackle.publish("Hi!", @tackle_options)

    sleep 10
  end

  after(:all) do
    @worker.kill
  end

  describe "message consumption" do
    it "consumes the message" do
      expect(@messages).to eq(["Hi!"])
    end

    it "cleares the queue" do
      expect(BunnyHelper.message_count("healthy-service.test-key")).to be(0)
    end

    it "leaves the dead queue empty" do
      expect(BunnyHelper.message_count("healthy-service.test-key.dead")).to be(0)
    end
  end
end
