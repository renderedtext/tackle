require "tackle/rabbit"
require "tackle/retry"

module Tackle
  class Worker
    include Tackle::TackleLogger

    def initialize(options = {})
      @options = options
      @logger = options[:logger]
    end

    def perform(&block)
      rabbit = Tackle::Rabbit.new(@options)
      rabbit.connect

      tackle_log("Subscribing to queue...")
      rabbit.queue.subscribe(:manual_ack => true, :block => true) do |delivery_info, properties, body|

        tackle_log("Received message")

        begin
          tackle_log("Calling message processor...")
          block.call(body)
          rabbit.channel.ack(delivery_info.delivery_tag)
          tackle_log("Successfully processed message")
        rescue Exception => ex
          tackle_log("Failed to process message. Received exception '#{ex}'")
          try_again = Tackle::Retry.new(rabbit, delivery_info, properties, body, @options)
          try_again.retry
        end
      end

    rescue Interrupt => _
      rabbit.close
    end

  end
end
