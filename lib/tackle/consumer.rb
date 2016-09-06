module Tackle
  require_relative "consumer/params"
  require_relative "consumer/connection"
  require_relative "consumer/message"
  require_relative "consumer/exchange"

  require_relative "consumer/queue"
  require_relative "consumer/main_queue"
  require_relative "consumer/delay_queue"
  require_relative "consumer/dead_queue"

  class Consumer

    def initialize(params)
      @params = params
      @logger = @params.logger

      setup_rabbit_connections
    end

    def setup_rabbit_connections
      @connection = Connection.new(@params.amqp_url, @params.on_uncaught_exception, @logger)

      @exchange    = Exchange.new(@params.service, @params.routing_key, @connection, @logger)
      @main_queue  = MainQueue.new(@exchange, @connection, @logger)
      @delay_queue = DelayQueue.new(@params.retry_delay, @exchange, @connection, @logger)
      @dead_queue  = DeadQueue.new(@exchange, @connection, @logger)

      @exchange.bind_to_exchange(@params.exchange)
    end

    def subscribe(&block)
      @main_queue.subscribe { |message| process_message(message, &block) }
    rescue Interrupt => _
      @connection.close
    rescue StandardError => ex
      @logger.error("An exception occured message='#{ex.message}'")

      raise ex
    end

    def process_message(message, &block)
      message.log_info "Calling message processor"

      block.call(message.payload)

      message.ack
    rescue StandardError => ex
      message.log_error "Failed to process message. Received exception '#{ex}'"

      redeliver_message(message)

      message.nack
    end

    def redeliver_message(message)
      message.log_error "Retry count #{message.retry_count}/#{@params.retry_limit}"

      if message.retry_count < @params.retry_limit
        @delay_queue.publish(message)
      else
        @dead_queue.publish(message)
      end
    end

  end
end
