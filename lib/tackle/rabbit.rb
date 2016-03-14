require "bunny"
require "tackle/tackle_logger"

module Tackle

  class Rabbit
    include Tackle::TackleLogger

    attr_reader :channel, :dead_letter_queue, :queue

    def initialize(options)
      @options = options
      @exchange_name = options[:exchange]
      @queue_name = options[:queue]
      @logger = options[:logger]
    end

    def connect
      @conn = Bunny.new
      @conn.start
      tackle_log("Connected to RabbitMQ")

      @channel = @conn.create_channel
      @channel.prefetch(1)
      tackle_log("Connected to channel")
      connect_queue
      connect_dead_letter_queue
    end

    def close
      @channel.close
      tackle_log("Closed channel")
      @conn.close
      tackle_log("Closed connection to RabbitMQ")
    end

    private

    def connect_queue
      @exchange = @channel.fanout(@exchange_name)
      tackle_log("Connected to exchange '#{@exchange_name}'")
      @queue = @channel.queue(@queue_name, :durable => true).bind(@exchange)
      tackle_log("Connected to queue '#{@queue_name}'")
    end

    def connect_dead_letter_queue
      dead_letter_exchange_name = "#{@exchange_name}.dead_letter_exchange"
      tackle_log("Connected to dead letter exchange '#{dead_letter_exchange_name}'")
      dead_letter_exchange = @channel.fanout(dead_letter_exchange_name)
      dead_letter_queue_name = "#{@exchange_name}_dead_letter_queue"
      @dead_letter_queue  = @channel.queue(dead_letter_queue_name, :durable => true,
                                          :arguments => {"x-dead-letter-exchange" => @exchange.name,
                                                         "x-message-ttl" => 5000}).bind(dead_letter_exchange)
      tackle_log("Connected to dead letter queue '#{dead_letter_queue_name}'")
    end

  end
end
