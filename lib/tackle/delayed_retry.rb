require "tackle/tackle_logger"

module Tackle

  class DelayedRetry
    include Tackle::TackleLogger

    def initialize(dead_letter_queue, properties, payload, options)
      @dead_letter_queue = dead_letter_queue
      @properties = properties
      @payload = payload
      @logger = options[:logger]
      @retry_limit = options[:retry_limit]
    end

    def schedule_retry
      tackle_log("Sending negative acknowledgement to source queue")

      if retry_count < @retry_limit
        tackle_log("Adding message to retry queue. Failure #{retry_count + 1}/#{@retry_limit}")
        @dead_letter_queue.publish(@payload, :headers => {:retry_count => retry_count + 1})
      else
        tackle_log("Reached #{retry_count + 1} retries. Discarding message.")
      end
    end

    private

    def retry_count
      if @properties.headers && @properties.headers["retry_count"]
        @properties.headers["retry_count"]
      else
        0
      end
    end

  end
end
