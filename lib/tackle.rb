require "tackle/version"

module Tackle
  require "tackle/worker"

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

    worker = Tackle::Worker.new(exchange_name,
                                routing_key,
                                queue_name,
                                :url => amqp_url,
                                :retry_limit => retry_limit,
                                :retry_delay => retry_delay,
                                :logger => logger)

    worker.subscribe(block)
  end
end
