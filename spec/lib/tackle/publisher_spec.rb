require "spec_helper"

describe Tackle::Publisher do
  let(:exchange_name) { "test-exchange" }
  let(:routing_key) { "test-routing-key" }

  describe "#publish" do
    before do
      @publisher = Tackle::Publisher.new(exchange_name, routing_key, "amqp://localhost:5672", Logger.new(STDOUT))
    end

    it "logs the message publishing" do
      @publisher.publish("test-message")
    end

    it "pushes a message into the exchange" do
      @publisher.publish("test-message")
    end

    context "when an exception occurs" do
      before do
        # stub something with an exception
      end

      it "logs the exception" do

      end

      it "re-raises the exception" do

      end
    end
  end
end
