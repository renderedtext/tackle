require "tackle/rabbit"
require "tackle/retry"

module Tackle
  class Worker

    def initialize(options = {})
      @options = options
    end

    def perform(&block)
      rabbit = Tackle::Rabbit.new(@options)
      rabbit.connect

      puts "waiting for messages"
      rabbit.queue.subscribe(:manual_ack => true, :block => true) do |delivery_info, properties, body|

        puts body

        begin
          block.call(body)
          rabbit.channel.ack(delivery_info.delivery_tag)
        rescue Exception => ex
          puts ex
          try_again = Tackle::Retry.new(rabbit, delivery_info, properties, body, @options)
          try_again.retry
        end
      end

    rescue Interrupt => _
      rabbit.close
    end

  end
end
