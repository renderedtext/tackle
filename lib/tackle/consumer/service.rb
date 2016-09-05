module Tackle
  class Consumer
    class Service
      def initialize(service_name, connection, logger)
        @service_name = service_name

        @connection = connection
        @logger = logger
      end

      def create_exchanges(remote_exchange_name, routing_key)
        service_exchange_name = "#{@service_name}.#{routing_key}"

        @remote_exchange  = create_exchange(remote_exchange_name)
        @service_exchange = create_exchange(service_exchange_name)
      end

      def create_queues(retry_delay, routing_key)
        service_queue_name = "#{@service_name}.#{routing_key}"
        delay_queue_name   = "#{service_queue_name}.delay.#{retry_delay}"
        dead_queue_name    = "#{service_queue_name}.dead"

        @queue       = create_queue(service_queue_name)
        @delay_queue = create_queue(delay_queue_name)
        @delay_queue = create_queue(dead_queue_name)

        @queue.bind(@servive_exchange, :routing_key => routing_key)
      end

      def consume(retry_limit, &consumer_block)
        options = { :manual_ack => true, :block => true }

        queue.subscribe(options) do |delivery_info, properties, payload|
          @logger.info("Calling message processor...")

          consumer_block.call(payload)
          @connection.channel.ack(delivery_info.delivery_tag)

          @logger.info("Successfully processed message")
        end
      rescue Exception => ex
        send(exception)
      end

      private

      def create_exchange(exchange_name)
        @logger.info("Creating exchange '#{exchange_name}'")

        @connection.channel.direct(exchange_name, :durable => true)
      end

      def create_queue(queue_name)
      @queue = @channel.queue(@queue_name, :durable => true).bind(@exchange, :routing_key => @routing_key)
      end

    end
  end
end
