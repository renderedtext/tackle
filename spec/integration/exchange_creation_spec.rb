require "spec_helper"

describe "Exchange creation" do
  before(:all) do
    @exceptions = []
    @messages = []

    @tackle_options = {
      :url => "amqp://localhost",
      :exchange => "test-exchange",
      :routing_key => "test-key",
      :service => "test-service",
      :retry_delay => 1,
      :retry_count => 3,
      :exception_handler => Proc.new { |exception| @exceptions << exception }
    }

    Thread.new do
      Tackle.consume(@tackle_options) do |message|
        @messages << message
      end
    end

    sleep 2
  end

  describe "exchanges" do
    it "creates the remote exchange if it doesn't exists" do
      exchange_name = "test-exchange"

      expect(BunnyHelper.exchange_exists?(exchange_name)).to eq(true)
    end

    it "creates the service specific exchange" do
      exchange_name = "test-service.test-key"

      expect(BunnyHelper.exchange_exists?(exchange_name)).to eq(true)
    end
  end
end
