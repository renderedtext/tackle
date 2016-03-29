module Tackle
  class Publisher
    include Tackle::TackleLogger

    def initialize(exchange_name, routing_key, url, logger)
      @exchange_name = exchange_name
      @routing_key = routing_key
      @url = url
      @logger = logger
    end

    def publish(message)
      tackle_log("Publishing message started exchange='#{@exchange_name}' routing_key='#{@routing_key}'")

      with_rabbit_connection do |conn|
        channel = conn.create_channel
        tackle_log("Created a communication channel")

        exchange = channel.direct(@exchange_name, :durable => true)
        tackle_log("Declared the exchange")

        exchange.publish(message, :routing_key => @routing_key, :persistent => true)
      end

      tackle_log("Publishing message finished exchange='#{@exchange_name}' routing_key='#{@routing_key}'")
    end

    private

    def with_rabbit_connection
      tackle_log("Establishing rabbit connection")

      conn = Bunny.new(@url)
      conn.start

      yield(conn)

      tackle_log("Established rabbit connection")
    rescue StandardError => ex
      tackle_log("An exception occured while sending the message exception='#{ex.class.name}' message='#{ex.message}'")

      raise ex
    ensure
      tackle_log("Clossing rabbit connection")

      conn.close if conn
    end

  end
end
