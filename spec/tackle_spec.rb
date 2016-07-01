require "spec_helper"

describe Tackle do

  it "has a version number" do
    expect(Tackle::VERSION).not_to be nil
  end

  describe "rabbit based communication" do
    let(:exchange) { "communication-test-exchange" }
    let(:routing_key) { "communication-test-routing-key" }
    let(:queue_name) { "communication-test-queue" }

    before do
      @subscribe_options = {
        :exchange => exchange,
        :routing_key => routing_key,
        :queue => queue_name
      }
    end

    it "transmits the messages through rabbit" do
      received_messages = []

      Thread.new do
        Tackle.subscribe(@subscribe_options) do |message|
          received_messages << message + "!!!"
        end
      end

      sleep(1)

      Tackle.publish("Hello World", :exchange => exchange, :routing_key => routing_key)

      sleep(1)

      expect(received_messages).to eq ["Hello World!!!"]
    end

    it "allows consumer to handle exceptions" do
      exception_handler = double(:exception_handler)
      on_uncaught_exception = proc { |ex| exception_handler.notify(ex.message) }
      @subscribe_options.merge!({ :on_uncaught_exception => on_uncaught_exception })

      allow(exception_handler).to receive(:notify).with("exception during processing message")
      expect(exception_handler).to receive(:notify).with("exception during processing message")

      Thread.new do
        Tackle.subscribe(@subscribe_options) do |message|
          raise "exception during processing message"
        end
      end

      sleep(1)

      Tackle.publish("Hello World", :exchange => @subscribe_options[:exchange], :routing_key => @subscribe_options[:routing_key])

    end
  end


end
