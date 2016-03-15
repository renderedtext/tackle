require "tackle/rabbit"
require "tackle/delayed_retry"

module Tackle
  class Worker
    include Tackle::TackleLogger

    attr_reader :rabbit

    def initialize(options = {})
      @options = options
      @logger = options[:logger]
      @rabbit = Tackle::Rabbit.new(@options)
    end

    def connect
      @rabbit.connect
    end

    def perform(&block)
      tackle_log("Subscribing to queue...")
      rabbit.queue.subscribe(:manual_ack => true,
                             :block => true) do |delivery_info, properties, payload|

        tackle_log("Received message. Processing...")
        process_message(delivery_info, properties, payload, block)
        tackle_log("Done with processing message.")

      end
    rescue Interrupt => _
      rabbit.close
    end

    def process_message(delivery_info, properties, payload, block)
      begin
        tackle_log("Calling message processor...")
        block.call(payload)
        @rabbit.channel.ack(delivery_info.delivery_tag)
        tackle_log("Successfully processed message")
      rescue Exception => ex
        tackle_log("Failed to process message. Received exception '#{ex}'")
        try_again = Tackle::DelayedRetry.new(@rabbit.dead_letter_queue,
                                             properties,
                                             payload,
                                             @options)
        try_again.schedule_retry
        @rabbit.channel.nack(delivery_info.delivery_tag)
      end
    end

  end
end
