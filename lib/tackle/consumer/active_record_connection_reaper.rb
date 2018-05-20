module Tackle
  class Consumer
    module ActiveRecordConnectionReaper
      module_function

      #
      # In case of a database failover, the active database connection can get
      # stuck and unable to re-connect.
      #
      # It is important to clear all active connections after when a message
      # is consumed. In case of a database failover, a new fresh connection will
      # be created that is able to communicate with the database properly.
      #
      # This technique is borrowed from Sidekiq:
      #
      # <https://github.com/mperham/sidekiq/blob/5-0/lib/sidekiq/middleware/server/active_record.rb>

      def run
        yield
      ensure
        #
        # This is no longer necessary in Rails 5+
        #
        if defined?(::ActiveRecord) && ActiveRecord::VERSION::MAJOR < 5
          ::ActiveRecord::Base.clear_active_connections!
        end
      end

    end
  end
end
