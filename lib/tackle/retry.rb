require "tackle/tackle_logger"
require "byebug"

module Tackle

  class Retry
    include Tackle::TackleLogger

    def initialize(rabbit, delivery_info, properties, body, options)
      @rabbit = rabbit
      @delivery_info = delivery_info
      @properties = properties
      @body = body
      @options = options
      @logger = options[:logger]
      @retry_limit = options[:retry_limit]
    end

    def retry
      tackle_log("Sending negative acknowledgement to source queue")
      @rabbit.channel.nack(@delivery_info.delivery_tag)

      if failure_count + 1 <= @retry_limit
        tackle_log("Adding message to retry queue. Failure #{failure_count + 1}/#{@retry_limit}")
        @rabbit.dead_letter_queue.publish(@body, :headers => {:failure_count => failure_count + 1})
      else
        tackle_log("Reached #{failure_count + 1} failures. Discarding message.")
      end
    end

    private

    def failure_count
      if @properties.headers
        failure_count = @properties.headers["failure_count"] || 0
      else
        failure_count = 0
      end
    end

  end
end
