require "spec_helper"
require "tackle/delayed_retry"

describe Tackle::DelayedRetry do
  let(:logger) { double(Logger).as_null_object }
  let(:dead_letter_queue) { double("dead_letter_queue") }
  let(:properties) { double("properties", :headers => nil) }
  let(:payload) { double("payload") }

  before do
    @delayed_retry = Tackle::DelayedRetry.new(dead_letter_queue,
                                              properties,
                                              payload,
                                              3,
                                              logger)
  end

  describe "schedule_retry" do

    context "number of retries is lower than the retries limit" do
      before do
        allow(properties).to receive(:headers) { {"retry_count" => 1} }
      end

      it "pushes message onto dead letter queue" do
        expect(dead_letter_queue).to receive(:publish)

        @delayed_retry.schedule_retry
      end
    end

    context "number of retries is not lower than the retries limit" do
      before do
        allow(properties).to receive(:headers) { {"retry_count" => 3} }
      end

      it "does nothing - discards the message" do
        expect(dead_letter_queue).not_to receive(:publish)

        @delayed_retry.schedule_retry
      end
    end

  end
end
