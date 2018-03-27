require 'json'
require 'socket'
require 'thread'
require 'securerandom'

module CloudWatchLogger
  module Client

    def self.new(credentials, log_group_name, log_stream_name=nil, opts={})
      unless log_group_name
        raise LogGroupNameRequired.new
      end

      CloudWatchLogger::Client::AWS_SDK.new(credentials, log_group_name, log_stream_name, opts)
    end

    module InstanceMethods
      def formatter
        proc do |severity, datetime, progname, msg|
          # Assume it's stringified Lograge JSON, so append some other goodies
          # or return the message if it's something else.
          begin
            JSON.dump(
              JSON.parse(msg).merge({
                severity: severity,
                pid: Process.pid,
                thread: Thread.current.object_id,
              })
            )
          rescue
            msg
          end
        end
      end

      def setup_credentials(credentials)
        @credentials = credentials
      end

      def setup_log_group_name(name)
        @log_group_name = name
      end

      def setup_log_stream_name(name)
        @log_stream_name = name
        if @log_stream_name.nil?
          @log_stream_name = "#{Socket.gethostname}-#{SecureRandom.uuid}"
        end
      end

    end

  end
end

require File.join(File.dirname(__FILE__), 'client', 'aws_sdk')
