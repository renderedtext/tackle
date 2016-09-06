module Tackle
  require_relative "consumer/params"
  require_relative "consumer/service"
  require_relative "consumer/connection"
  require_relative "consumer/message"
  require_relative "consumer/message_processor"

  class Consumer

    def initialize(params)
      @params = params
      @logger = @params.logger

      @connection = Connection.new(@params, @logger)
    end

    def subscribe(&block)
      @connection.connect

      service = Service.new(@params, @connection, @logger)
      service.create_exchanges
      service.create_queues
      service.bind

      processor = MessageProcessor.new(@params, service, @logger, &block)

      service.subscribe do |delivery_info, properties, payload|
          message = Message.new(@connection, @logger, delivery_info, properties, payload)

          processor.process(message)
      end
    rescue Interrupt => _
      @connection.close
    rescue StandardError => ex
      @logger.error("An exception occured message='#{ex.message}'")

      raise ex
    end

  end
end
