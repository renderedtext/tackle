require "tackle/version"
require "bunny"
require "logger"

module Tackle
  require "tackle/connection"
  require "tackle/publisher"
  require "tackle/consumer"

  module_function

  def consume(params = {}, &block)
    params   = Tackle::Consumer::Params.new(params)
    consumer = Tackle::Consumer.new(params)

    consumer.subscribe(&block)
  end

  def publish(message, options = {})
    # required
    exchange_name = options.fetch(:exchange)
    routing_key   = options.fetch(:routing_key)

    # optional
    amqp_url    = options[:url] || "amqp://localhost:5672"
    logger      = options[:logger] || Logger.new(STDOUT)

    publisher = Tackle::Publisher.new(exchange_name, routing_key, amqp_url, logger)

    publisher.publish(message)
  end
end
