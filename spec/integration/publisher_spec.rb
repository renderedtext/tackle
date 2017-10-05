require "spec_helper"

describe "Publishing messages to a queue" do

  before do
    @tackle_options = {
      :url => "amqp://localhost",
      :exchange => "test-exchange",
      :routing_key => "test-key",
      :service => "healthy-service",
      :retry_delay => 1,
      :retry_limit => 3
    }
  end

  context "can't establish connection to server" do
    before do
      allow(Bunny).to receive(:new).and_raise(Timeout::Error)
    end

    it "consumes the message" do
      expect { Tackle.publish("Hi!", @tackle_options) }.to raise_exception(Timeout::Error)
    end
  end

end
