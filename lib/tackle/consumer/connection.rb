module Tackle
  class Consumer
    class Connection
      def initialize(params, logger)
        @params = params
        @logger = logger
      end

      def connect
        @connection = Bunny.new(@amqp_url)
        @connection.start

        @logger.info("Connected to RabbitMQ")

        @channel = @connection.create_channel
        @channel.prefetch(1)
        @channel.on_uncaught_exception(@params.exception_handler)

        @logger.info("Connected to channel")
      rescue StandardError => ex
        @logger.error("An exception occured while connecting to Rabbit server message='#{ex.message}'")

        raise ex
      end

      def close
        @channel.close
        @logger.info("Closed channel")

        @connection.close
        @logger.info("Closed connection to RabbitMQ")
      end

    end
  end
end
