require "spec_helper"

describe Tackle::Publisher do
  let(:exchange_name) { "test-exchange" }
  let(:routing_key) { "test-routing-key" }

  describe "#publish" do
    before do
      @publisher = Tackle::Publisher.new(exchange_name, routing_key, "amqp://localhost:5672", Logger.new(STDOUT))

      allow(@publisher).to receive(:tackle_log)

      @worker = Tackle::Worker.new(exchange_name, routing_key, "publishing-test-queue")
    end

    it "logs the message publishing" do
      expect(@publisher).to receive(:tackle_log).with(/Publishing message started/)

      expect(@publisher).to receive(:tackle_log).with(/Publishing message finished/)

      @publisher.publish("test-message")
    end

    it "pushes a message into the exchange" do
      @publisher.publish("test-message")

      _, _, payload = @worker.rabbit.queue.pop(:manual_ack => true)

      expect(payload).to eq("test-message")
    end

    context "when an exception occurs" do
      before do
        allow(Bunny).to receive(:new) { raise "test exception" }
      end

      it "logs the exception" do
        expect(@publisher).to receive(:tackle_log).with("An exception occured while sending the message exception='RuntimeError' message='test exception'")

        expect { @publisher.publish("test-message") }.to raise_exception("test exception")
      end

      it "re-raises the exception" do
        expect { @publisher.publish("test-message") }.to raise_exception("test exception")
      end
    end
  end
end
