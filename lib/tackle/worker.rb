require "tackle/rabbit"
require "tackle/delayed_retry"

module Tackle
  class Worker
    include Tackle::TackleLogger

    attr_reader :rabbit

    # Initializes now worker
    #
    # @param [String] exchange_name Name of the exchange queue is connected to.
    # @param [String] routing_key Routing key for binding queue to exchange
    # @param [String] queue_name Name of the queue worker is processing.
    # @param [Hash] options Worker options for RabbitMQ connection, retries and logger.
    #
    # @option options [String] :url AMQP connection url. Defaults to 'localhost'
    # @option options [Integer] :retry_limit Number of times message processing should be retried in case of an exception.
    # @option options [Integer] :retry_delay Delay between processing retries. Dafaults to 30 seconds. Cannot be changed without deleting or renameing a queue.
    # @option options [Logger] :logger Logger instance. Defaults to standard output.
    #
    # @api public
    def initialize(exchange_name, routing_key, queue_name, options = {})
      @queue_name = queue_name
      @amqp_url = options[:url] || "amqp://localhost:5672"
      @retry_limit = options[:retry_limit] || 8
      @retry_delay = (options[:retry_delay] || 30) * 1000 #ms
      @logger = options[:logger] || Logger.new(STDOUT)

      @rabbit = Tackle::Rabbit.new(exchange_name,
                                   routing_key,
                                   @queue_name,
                                   @amqp_url,
                                   @retry_delay,
                                   @logger)

      @rabbit.connect
      @rabbit.on_uncaught_exception(options[:on_uncaught_exception]) if options[:on_uncaught_exception]
    end

    # Subscribes for message deliveries
    #
    # @param [Block] Accepts a block that accepts message
    #
    # @api public
    def subscribe(&block)
      tackle_log("Subscribing to queue '#{@queue_name}'...")
      rabbit.queue.subscribe(:manual_ack => true,
                             :block => true) do |delivery_info, properties, payload|

        tackle_log("Received message. Processing...")
        process_message(delivery_info, properties, payload, block)
        tackle_log("Done with processing message.")

      end
    rescue Interrupt => _
      rabbit.close
    rescue StandardError => ex
      tackle_log("An exception occured message='#{ex.message}'")

      raise ex
    end

    def process_message(delivery_info, properties, payload, block)
      begin
        tackle_log("Calling message processor...")
        block.call(payload)
        @rabbit.channel.ack(delivery_info.delivery_tag)
        tackle_log("Successfully processed message")
      rescue Exception => ex
        tackle_log("Failed to process message. Received exception '#{ex}'")
        try_again = Tackle::DelayedRetry.new(@rabbit.dead_letter_queue,
                                             properties,
                                             payload,
                                             @retry_limit,
                                             @logger)
        try_again.schedule_retry
        tackle_log("Sending negative acknowledgement to source queue...")
        @rabbit.channel.nack(delivery_info.delivery_tag)
        tackle_log("Negative acknowledgement sent")

        raise ex
      end
    end
  end
end
