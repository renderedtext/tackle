require "spec_helper"

describe "Queue creation" do
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
  end

  describe "queues" do
    it "creates the service specific queue" do
      queue_name = "test-service.test-key"

      expect(BunnyHelper.queue_exists?(queue_name)).to eq(true)
    end

    it "creates a delay queue" do
      queue_name = "test-service.test-key.delay.1"

      expect(BunnyHelper.queue_exists?(queue_name)).to eq(true)
    end

    it "creates a dead queue" do
      queue_name = "test-service.test-key.dead"

      expect(BunnyHelper.queue_exists?(queue_name)).to eq(true)
    end
  end
end
