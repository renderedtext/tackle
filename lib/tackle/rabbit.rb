require "bunny"
require "tackle/tackle_logger"

module Tackle

  class Rabbit
    include Tackle::TackleLogger

    attr_reader :channel, :dead_letter_queue, :queue

    def initialize(exchange_name, routing_key, queue_name, amqp_url, retry_delay, logger)
      @exchange_name = exchange_name
      @routing_key = routing_key
      @queue_name = queue_name
      @amqp_url = amqp_url
      @retry_delay = retry_delay
      @logger = logger
    end

    def connect
      @conn = Bunny.new(@amqp_url)
      @conn.start
      tackle_log("Connected to RabbitMQ")

      @channel = @conn.create_channel
      @channel.prefetch(1)

      tackle_log("Connected to channel")
      connect_queue
      connect_dead_letter_queue
    rescue StandardError => ex
      tackle_log("An exception occured while connecting to the server message='#{ex.message}'")

      raise ex
    end

    def close
      @channel.close
      tackle_log("Closed channel")
      @conn.close
      tackle_log("Closed connection to RabbitMQ")
    end

    def dead_letter_exchange_name
      "#{@exchange_name}.dead_letter_exchange"
    end

    def dead_letter_queue_name
      "#{@exchange_name}_dead_letter_queue"
    end

    private

    def connect_queue
      @exchange = @channel.direct(@exchange_name)
      tackle_log("Connected to exchange '#{@exchange_name}'")

      @queue = @channel.queue(@queue_name, :durable => true).bind(@exchange, :routing_key => @routing_key)

      tackle_log("Connected to queue '#{@queue_name}'")
    end

    def connect_dead_letter_queue
      tackle_log("Connected to dead letter exchange '#{dead_letter_exchange_name}'")

      dead_letter_exchange = @channel.direct(dead_letter_exchange_name)

      queue_options = {
        :durable => true,
        :arguments => {
          "x-dead-letter-exchange" => @exchange.name,
          "x-message-ttl" => @retry_delay
        }
      }

      @dead_letter_queue = @channel.queue(dead_letter_queue_name, queue_options).bind(dead_letter_exchange)

      tackle_log("Connected to dead letter queue '#{dead_letter_queue_name}'")
    end

  end
end
