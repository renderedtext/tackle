module Tackle
  class Consumer
    class Queue

      attr_reader :name

      def initialize(name, options, connection, logger)
        @name = name
        @connection = connection
        @logger = logger
        @options = options

        @amqp_queue = create_amqp_queue
      end

      def create_amqp_queue
        @logger.info("Creating queue '#{@name}'")
        @connection.channel.queue(@name, @options)
      rescue Exception => ex
        @logger.error "Failed to create queue '#{ex}'"
        raise ex
      end

    end
  end
end
