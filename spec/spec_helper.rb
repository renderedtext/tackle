$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require "tackle"

module BunnyHelper
  module_function

  def queue_exists?(queue_name)
    conn = Bunny.new
    conn.start

    conn.queue_exists?(queue_name)
  ensure
    conn.close
  end

  def exchange_exists?(exchange_name)
    conn = Bunny.new
    conn.start

    conn.exchange_exists?(exchange_name)
  ensure
    conn.close
  end

  def message_count(queue_name)
    conn = Bunny.new
    conn.start

    raise "Queue doesn't exists" unless conn.queue_exists?(queue_name)

    channel = conn.channel
    queue = channel.queue(queue_name, :passive => true)

    queue.message_count
  ensure
    conn.close
  end
end
