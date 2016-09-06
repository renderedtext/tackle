module Tackle
  class Consumer
    class Message
      def initialize(service, delivery_info, properties, payload)
        @service = service
        @logger = @service.logger

        @delivery_info = delivery_info
        @properties    = properties
        @payload       = payload

        @retry_count = calculate_retry_count
      end

      def calculate_retry_count
        if @properties.headers && @properties.headers["retry_count"]
          @properties.headers["retry_count"]
        else
          0
        end
      end

      def process(&block)
        log_info "Calling message processor"

        block.call(@payload)

        @service.connection.channel.ack(@delivery_info.delivery_tag)

        log_info "Successfully processed message"
      rescue StandardError => ex
        log_error "Failed to process message. Received exception '#{ex}'"
        log_error "Retry count #{@retry_count}/#{@service.retry_limit}"

        if @retry_count < @service.retry_limit
          delayed_retry
        else
          push_to_dead_queue
        end

        log_error "Sending negative acknowledgement to source queue"
        @service.connection.channel.nack(@delivery_info.delivery_tag)
        log_error "Negative acknowledgement sent"
      end

      def delayed_retry
        log_error "Pushing message to delay queue delay='#{@service.retry_delay}'"

        headers = {
          :headers => {
            :retry_count => @retry_count + 1
          }
        }

        @service.delay_queue.publish(@payload, headers)

        log_error "Message pushed to delay queue"
      end

      def push_to_dead_queue
        log_error "Pushing message to dead queue"

        @service.dead_queue.publish(@payload)

        log_error "Message pushed to dead queue"
      rescue StandardError => ex
        log_error "Error while pushing message to dead queue exception='#{ex}'"
        raise ex
      end

      def log_info(message)
        @logger.info("[delivery_tag=#{@delivery_info.delivery_tag}] #{message}")
      end

      def log_error(message)
        @logger.error("[delivery_tag=#{@delivery_info.delivery_tag}] #{message}")
      end

    end
  end
end
