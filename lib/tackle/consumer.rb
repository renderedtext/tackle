module Tackle
  require_relative "consumer/params"
  require_relative "consumer/service"
  require_relative "consumer/connection"
  require_relative "consumer/message"

  class Consumer

    def initialize(params)
      @params = params
      @logger = @params.logger
    end

    def subscribe(&block)
      connection = Tackle::Consumer::Connection.new(@params, @logger)
      connection.connect

      service = Tackle::Consumer::Service.new(@params, connection, @logger)
      service.create_exchanges
      service.create_queues
      service.bind

      service.subscribe do |delivery_info, properties, payload|
        message = Tackle::Consumer::Message.new(service,
                                                delivery_info,
                                                properties,
                                                payload)
        message.process(&block)
      end
    rescue Interrupt => _
      connection.close
    rescue StandardError => ex
      @logger.error("An exception occured message='#{ex.message}'")

      raise ex
    end

  end
end
