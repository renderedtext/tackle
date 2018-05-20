module Tackle
  class Connection
    attr_reader :channel

    def initialize(amqp_url, exception_handler, logger, connection = nil)
      @amqp_url = amqp_url
      @exception_handler = exception_handler
      @logger = logger
      @connection = connection

      connect
    end

    def connect
      @logger.info("Connecting to RabbitMQ")

      @connection ||= Bunny.new(@amqp_url)
      @connection.start

      @logger.info("Connected to RabbitMQ")

      @channel = @connection.create_channel
      @channel.prefetch(1)
      @channel.on_uncaught_exception(&@exception_handler)

      @logger.info("Connected to channel")
    rescue Timeout::Error => ex
      @logger.error("Timeout while connecting to RabbitMQ server message='#{ex}'")

      raise ex
    rescue StandardError => ex
      @logger.error("Error while connecting to RabbitMQ message='#{ex}'")

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
