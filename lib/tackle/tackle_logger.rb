module Tackle

  module TackleLogger

    def tackle_log(message)
      pid = Process.pid

      whole_message = "tackle - pid=#{pid} message=#{message}"

      @logger.info(whole_message)
    end
  end
end
