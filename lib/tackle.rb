require "tackle/version"

module Tackle
  require "tackle/worker"
  require "tackle/publisher"

  def self.subscribe(options = {}, &block)
    # required
    exchange_name = options.fetch(:exchange)
    routing_key   = options.fetch(:routing_key)
    queue_name    = options.fetch(:queue)

    # optional
    amqp_url    = options[:url]
    retry_limit = options[:retry_limit]
    retry_delay = options[:retry_delay]
    logger      = options[:logger]
    on_uncaught_exception = options[:on_uncaught_exception]

    worker = Tackle::Worker.new(exchange_name,
                                routing_key,
                                queue_name,
                                :url => amqp_url,
                                :retry_limit => retry_limit,
                                :retry_delay => retry_delay,
                                :logger => logger,
                                :on_uncaught_exception => on_uncaught_exception)

    worker.subscribe(&block)
  end

  def self.publish(message, options = {})
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
