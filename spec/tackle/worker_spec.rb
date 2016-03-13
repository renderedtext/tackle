require 'spec_helper'

describe Tackle::Worker do
  class DummyWorker
    def initialize
      @worker = Tackle::Worker.new(:url => "localhost",
                                   :exchange => "test-exchange",
                                   :queue => "test-queue",
                                   :retry_limit => 10)
    end

    def run
      @worker.perform do |message|
        puts "got message: #{message}"
        1 / 0
        true
      end
    end
  end

  before do
    @worker = DummyWorker.new
  end

  it 'has a version number' do
    @worker.run
  end

  it "send message" do
    require "bunny"

    conn = Bunny.new
    conn.start
    channel = conn.create_channel

    x = channel.fanout("test-exchange")

    x.publish "nest"
  end
end
