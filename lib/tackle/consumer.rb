module Tackle
  class Consumer

    def initialize(params)
      @params = params
      @logger = Logger.new(STDOUT)
    end

    def subscribe(&block)
      connection = Tackle::Consumer::Connection.new(@params, @logger)
      connection.connect

      service = Tackle::Consumer::Service.new(@params.service, connection, @logger)
      service.create_exchanges(@params.exchange)
      service.create_queues(@params.retry_delay)

      service.consume(@params.retry_limit, &block)
    rescue Interrupt => _
      connection.close
    rescue StandardError => ex
      @logger.error("An exception occured message='#{ex.message}'")

      raise ex
    end

  end
end
