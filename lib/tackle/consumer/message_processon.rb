module Tackle
  class Consumer
    class MessageProcessor
      def initialize(rabbit_channel, logger, &consumer_block)
        @rabbit_channel = rabbit_channel
        @logger = logger

        @consumer_block = consumer_block
      end

      def process(delivery_info, properties, payload)
        @logger.info("Calling message processor...")

        @consumer_block.call(payload)
        @rabbit_channel.ack(delivery_info.delivery_tag)

        @logger.info("Successfully processed message")
      rescue Exception => ex
        handle_consumer_exception(exception)
      end

      private

      def handle_consumer_exception(delivery_info, properties, payload, exception)
        @logger.error("Failed to process message. Received exception '#{ex}'")


        @logger.erorr("Sending negative acknowledgement to source queue...")
        @rabbit_channel.nack(delivery_info.delivery_tag)

        @logger.info("Negative acknowledgement sent")

        raise ex
      end

    end
  end
end
