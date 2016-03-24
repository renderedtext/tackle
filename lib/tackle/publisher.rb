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
      tackle_log("Publishing message started to exchange='#{@exchange_name}' routing_key='#{@routing_key}'")

      tackle_log("Publishing message finished to exchange='#{@exchange_name}' routing_key='#{@routing_key}'")
    end

  end
end
