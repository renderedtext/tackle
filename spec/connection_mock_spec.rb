require "spec_helper"

describe "Connection mock for test" do

  before do
    @tackle_options = {
      :url => "amqp://localhost",
      :exchange => "test-exchange",
      :routing_key => "test-mock-key",
      :service => "healthy-mock-service",
      :connection => Object.new
    }
  end

  it "raise NoMethodError" do
    expect { Tackle.publish("humm?", @tackle_options) }.to raise_exception(NoMethodError)
  end
end
