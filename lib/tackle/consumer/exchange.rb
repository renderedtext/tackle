module Tackle
  class Consumer
    class Exchange

      attr_reader :routing_key

      def initialize(service_name, routing_key, connection, logger)
        @service_name = service_name
        @routing_key = routing_key
        @connection = connection
        @logger = logger

        @logger.info("Creating local exchange '#{name}'")
        @amqp_exchange = @connection.channel.direct(name, :durable => true)
      end

      def name
        "#{@service_name}.#{@routing_key}"
      end

      def bind_to_exchange(remote_exchange_name)
        @logger.info("Creating remote exchange '#{remote_exchange_name}'")
        @connection.channel.direct(remote_exchange_name, :durable => true)

        @logger.info("Binding exchange '#{name}' to exchange '#{remote_exchange_name}'")
        @amqp_exchange.bind(remote_exchange_name, :routing_key => routing_key)
      rescue Exception => ex
        @logger.error "Binding to remote exchange failed #{ex}"
        raise ex
      end

    end
  end
end
