module Tackle
  class Publisher

    def initialize(exchange_name, routing_key, url, logger)
      @exchange_name = exchange_name
      @routing_key = routing_key
      @url = url
      @logger = logger
    end

    def publish(message)
      connection = Tackle::Connection.new(@url, nil, @logger)

      @logger.info("Declaring exchange='#{@exchange_name}'")
      exchange = connection.channel.direct(@exchange_name, :durable => true)
      @logger.info("Declared exchange='#{@exchange_name}'")

      @logger.info("Publishing message exchange='#{@exchange_name}' routing_key='#{@routing_key}'")
      exchange.publish(message, :routing_key => @routing_key, :persistent => true)
      @logger.info("Publishing message finished exchange='#{@exchange_name}' routing_key='#{@routing_key}'")
    ensure
      connection.close
    end

  end
end
