module Tackle
  class Consumer
    class Service

      attr_reader :logger
      attr_reader :connection
      attr_reader :retry_limit

      attr_reader :queue
      attr_reader :delay_queue
      attr_reader :dead_queue

      def initialize(params, connection, logger)
        @params      = params
        @connection  = connection
        @logger      = logger
        @retry_limit = params.retry_limit

        @remote_exchange_name = @params.exchange
        @local_exchange_name  = "#{@params.service}.#{@params.routing_key}"
      end

      def create_exchanges
        @remote_exchange = @connection.create_exchange(@remote_exchange_name)
        @local_exchange  = @connection.create_exchange(@local_exchange_name)
      end

      def create_queues
        queue_name       = @local_exchange_name
        delay_queue_name = "#{queue_name}.delay.#{@params.retry_delay}"
        dead_queue_name  = "#{queue_name}.dead"

        delay_options = {
          :arguments => {
            "x-dead-letter-exchange" => @local_exchange_name,
            "x-dead-letter-routing-key" => @params.routing_key,
            "x-message-ttl" => @params.retry_delay * 1000 # miliseconds
          }
        }

        @queue       = @connection.create_queue(queue_name)
        @delay_queue = @connection.create_queue(delay_queue_name, delay_options)
        @dead_queue  = @connection.create_queue(dead_queue_name)

        @queue.bind(@local_exchange, :routing_key => @params.routing_key)
      end

      def subscribe(&block)
        options = { :manual_ack => true, :block => true }

        @queue.subscribe(&block)
      end

    end
  end
end
