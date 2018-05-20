require "tackle/version"
require "bunny"
require "logger"

module Tackle
  require "tackle/connection"
  require "tackle/publisher"
  require "tackle/consumer"

  ACK = :ack
  NACK = :nack

  module_function

  def consume(params = {}, &block)
    params   = Tackle::Consumer::Params.new(params)
    consumer = Tackle::Consumer.new(params)

    consumer.subscribe(&block)
  end

  def publish(message, options = {})
    url         = options.fetch(:url)
    exchange    = options.fetch(:exchange)
    routing_key = options.fetch(:routing_key)
    logger      = options.fetch(:logger, Logger.new(STDOUT))
    connection  = options.fetch(:connection, nil)

    Tackle::Publisher.new(url, exchange, routing_key, logger, connection).publish(message)
  end
end
