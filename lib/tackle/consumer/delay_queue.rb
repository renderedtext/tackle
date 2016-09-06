module Tackle
  class Consumer
    class DelayQueue < Tackle::Consumer::Queue

      def initialize(retry_delay, exchange, connection, logger)
        name = "#{exchange.name}.delay.#{retry_delay}"

        options = {
          :durable => true,
          :arguments => {
            "x-dead-letter-exchange" => exchange.name,
            "x-dead-letter-routing-key" => exchange.routing_key,
            "x-message-ttl" => retry_delay * 1000 # miliseconds
          }
        }

        super(name, options, connection, logger)
      end

      def publish(message)
        message.log_error "Pushing message to delay queue delay='#{@retry_delay}'"

        headers = {
          :headers => {
            :retry_count => message.retry_count + 1
          }
        }

        @amqp_queue.publish(message.payload, headers)

        message.log_error "Message pushed to delay queue"
      rescue StandardError => ex
        message.log_error "Error while pushing message to delay queue exception='#{ex}'"

        raise ex
      end

    end
  end
end
