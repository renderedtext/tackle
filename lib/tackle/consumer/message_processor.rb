module Tackle
  class Consumer
    class MessageProcessor

      def initialize(params, service, logger, &consumer_block)
        @params = params
        @service = service
        @logger = logger

        @consumer_block = consumer_block

        @retry_limit = @params.retry_limit
      end

      def process(message)
        message.log_info "Calling message processor"

        @consumer_block.call(message.payload)

        message.ack
      rescue StandardError => ex
        message.log_error "Failed to process message. Received exception '#{ex}'"

        handle_failed_massage(message)
        message.nack
      end

      def handle_failed_massage(message)
        message.log_error "Retry count #{message.retry_count}/#{@retry_limit}"

        if message.retry_count < @retry_limit
          delayed_retry(message)
        else
          push_to_dead_queue(message)
        end
      end

      def delayed_retry(message)
        message.log_error "Pushing message to delay queue delay='#{@service.retry_delay}'"

        headers = {
          :headers => {
            :retry_count => message.retry_count + 1
          }
        }

        @service.delay_queue.publish(message.payload, headers)

        message.log_error "Message pushed to delay queue"
      end

      def push_to_dead_queue(message)
        message.log_error "Pushing message to dead queue"

        @service.dead_queue.publish(message.payload)

        message.log_error "Message pushed to dead queue"
      rescue StandardError => ex
        message.log_error "Error while pushing message to dead queue exception='#{ex}'"

        raise ex
      end

    end
  end
end
