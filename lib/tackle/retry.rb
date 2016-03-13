module Tackle

  class Retry

    def initialize(rabbit, delivery_info, properties, body, options)
      @rabbit = rabbit
      @delivery_info = delivery_info
      @properties = properties
      @body = body
      @options = options
      @retry_limit = options[:retry_limit]
    end

    def retry
      @rabbit.channel.nack(@delivery_info.delivery_tag, false)
      puts "nack message"

      if failure_count >= @retry_limit
        puts "will not retry any more. Discarding message"
      else
        @rabbit.dead_letter_queue.publish(@body, :headers => {:failure_count => failure_count + 1})
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
