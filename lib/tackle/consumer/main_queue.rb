module Tackle
  class Consumer
    class MainQueue < Tackle::Consumer::Queue

      def initialize(exchange, connection, logger)
        @exchange = exchange

        name = @exchange.name
        options = { :durable => true }

        super(name, options, connection, logger)

        bind_to_exchange
      end

      def bind_to_exchange
        @logger.info("Binding queue '#{name}' to exchange '#{@exchange.name}' with routing_key '#{@exchange.routing_key}'")

        @amqp_queue.bind(@exchange, :routing_key => @exchange.routing_key)
      rescue Exception => ex
        @logger.error "Failed to bind queue to exchange '#{ex}'"
        raise ex
      end

      def subscribe(&block)
        options = { :manual_ack => true, :block => true }

        @amqp_queue.subscribe(options) do |delivery_info, properties, payload|
          message = Message.new(@connection,
                                @logger,
                                delivery_info,
                                properties,
                                payload)

          block.call(message)
        end
      end


    end
  end
end
