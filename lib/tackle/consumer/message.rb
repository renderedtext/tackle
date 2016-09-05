module Tackle
  class Consumer
    class Message
      def initialize(service, delivery_info, properties, payload)
        @service = service

        @delivery_info = delivery_info
        @properties    = properties
        @payload       = payload
      end

      def retry_count
        if @properties.headers && @properties.headers["retry_count"]
          @properties.headers["retry_count"]
        else
          0
        end
      end

      def process
        @logger.info("Calling message processor...")

        yield(@payload)
        @service.connection.channel.ack(@delivery_info.delivery_tag)

        @logger.info("Successfully processed message")
      rescue StandardError => ex
        @logger.info("Failed to process message. Received exception '#{ex}'")
        @logger.into("Retry count #{retry_count + 1}/#{@service.retry_limit}")

        if retry_count(properties) < @service.retry_limit
          delayed_retry
        else
          push_to_dead_queue
        end

        @logger.error("Sending negative acknowledgement to source queue...")
        @service.connection.channel.nack(@delivery_info.delivery_tag)
        @logger.error("Negative acknowledgement sent")
      end

      def delayed_retry
        @logger.info("Publishing to delay queue")

        headers = {
          :headers => {
            :retry_count => retry_count + 1
          }
        }

        @service.delay_queue.publish(@payload, headers)
      end

      def push_to_dead_queue
        @logger.info("Publishing to dead queue")

        @service.dead_queue.publish(payload)
      end

    end
  end
end
