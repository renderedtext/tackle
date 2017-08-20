module Tackle
  require_relative "consumer/params"
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
      @connection = Tackle::Connection.new(@params.amqp_url, @params.exception_handler, @logger)

      @exchange    = Exchange.new(@params.service, @params.routing_key, @connection, @logger)
      @main_queue  = MainQueue.new(@exchange, @connection, @logger)
      @delay_queue = DelayQueue.new(@params.retry_delay, @exchange, @connection, @logger)
      @dead_queue  = DeadQueue.new(@exchange, @connection, @logger)

      @exchange.bind_to_exchange(@params.exchange)
    end

    def subscribe(&block)
      @logger.info "Subscribing to the main queue '#{@main_queue.name}'"

      @main_queue.subscribe { |message| process_message(message, &block) }
    rescue Interrupt => _
      @connection.close
    rescue StandardError => ex
      @logger.error("An exception occured message='#{ex.message}'")

      raise ex
    end

    def process_message(message, &block)
      message.log_info "Calling message processor"

      response = block.call(message.payload)

      unless @params.manual_ack?
        response = Tackle::ACK
      end

      case response
      when Tackle::ACK
        message.ack
      when Tackle::NACK
        redeliver_message(message, "Received Tackle::NACK")
      else
        raise "Response must be either Tackle::ACK or Tackle::NACK"
      end
    rescue Exception => ex
      redeliver_message(message, "Received exception '#{ex}'")

      raise ex
    end

    def redeliver_message(message, reason)
      message.log_error "Failed to process message. #{reason}"
      message.log_error "Retry count #{message.retry_count}/#{@params.retry_limit}"

      if message.retry_count < @params.retry_limit
        @delay_queue.publish(message)
      else
        @dead_queue.publish(message)
      end

      message.nack
    end

  end
end
