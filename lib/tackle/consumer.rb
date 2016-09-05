module Tackle
  class Consumer

    def initialize(params)
      @params = params
      @logger = Logger.new(STDOUT)
    end

    def subscribe(&block)
      connection = Tackle::Consumer::Connection.new(@params, @logger)
      connection.connect

      processor = Tackle::Consumer::MessageProcessor.new(&block)
      options = { :manual_ack => true, :block => true }

      @queue.subscribe(options) do |delivery_info, properties, payload|
        @processor.process_message(delivery_info, properties, payload)
      end
    rescue Interrupt => _
      connection.close
    rescue StandardError => ex
      @logger.error("An exception occured message='#{ex.message}'")

      raise ex
    end

  end
end
