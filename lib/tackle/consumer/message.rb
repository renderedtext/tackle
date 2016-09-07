module Tackle
  class Consumer
    class Message

      attr_reader :payload
      attr_reader :properties
      attr_reader :payload

      def initialize(connection, logger, delivery_info, properties, payload)
        @connection = connection
        @logger = logger

        @delivery_info = delivery_info
        @properties    = properties
        @payload       = payload
      end

      def ack
        log_info "Sending positive acknowledgement to source queue"
        @connection.channel.ack(delivery_tag)
        log_info "Positive acknowledgement sent"
      end

      def nack
        log_error "Sending negative acknowledgement to source queue"
        @connection.channel.nack(delivery_tag)
        log_error "Negative acknowledgement sent"
      end

      def retry_count
        if @properties.headers && @properties.headers["retry_count"]
          @properties.headers["retry_count"]
        else
          0
        end
      end

      def delivery_tag
        @delivery_info.delivery_tag
      end

      def log_info(message)
        @logger.info("[delivery_tag=#{delivery_tag}] #{message}")
      end

      def log_error(message)
        @logger.error("[delivery_tag=#{delivery_tag}] #{message}")
      end

    end
  end
end
