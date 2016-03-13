require "bunny"

module Tackle

  class Rabbit

    attr_reader :channel, :dead_letter_queue, :queue

    def initialize(options)
      @options = options
      @exchange_name = options[:exchange]
      @queue_name = options[:queue]
    end

    def connect
      @conn = Bunny.new
      @conn.start

      @channel = @conn.create_channel
      @channel.prefetch(1)
      connect_queue
      connect_dead_letter_queue
    end

    def close
      @channel.close
      @conn.close
    end

    private

    def connect_queue
      @exchange = @channel.fanout(@exchange_name)
      @queue = @channel.queue(@queue_name, :durable => true).bind(@exchange)
    end

    def connect_dead_letter_queue
      dead_letter_exchange = @channel.fanout("#{@exchange_name}.dead_letter_exchange")
      @dead_letter_queue  = @channel.queue("#{@exchange_name}_dead_letter_queue", :durable => true,
                                          :arguments => {"x-dead-letter-exchange" => @exchange.name,
                                                         "x-message-ttl" => 1000}).bind(dead_letter_exchange)
    end

  end
end
