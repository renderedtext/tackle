module Tackle
  class Consumer
    class DeadQueue < Tackle::Consumer::Queue

      def initialize(exchange, connection, logger)
        name = "#{exchange.name}.dead"

        options = { :durable => true }

        super(name, options, connection, logger)
      end

      def publish(message)
        message.log_error "Pushing message to '#{name}'"

        @amqp_queue.publish(message.payload)

        message.log_error "Message pushed to '#{name}'"
      rescue StandardError => ex
        message.log_error "Error while pushing message exception='#{ex}'"

        raise ex
      end

    end
  end
end
