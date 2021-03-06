require 'itamae'
require 'logger'
require 'ansi/code'

module Itamae
  module Logger
    class Formatter
      attr_accessor :colored
      attr_accessor :depth

      INDENT_LENGTH = 3

      def initialize(*args)
        super

        @depth = 0
      end

      def call(severity, datetime, progname, msg)
        log = "%s : %s%s\n" % ["%5s" % severity, ' ' * INDENT_LENGTH * depth , msg2str(msg)]
        if colored
          color(log, severity)
        else
          log
        end
      end

      def indent
        @depth += 1
        yield
      ensure
        @depth -= 1
      end

      private
      def msg2str(msg)
        case msg
        when ::String
          msg
        when ::Exception
          "#{ msg.message } (#{ msg.class })\n" <<
          (msg.backtrace || []).join("\n")
        else
          msg.inspect
        end
      end

      def color(str, severity)
        color_code = case severity
                     when "INFO"
                       :green
                     when "WARN"
                       :magenta
                     when "ERROR"
                       :red
                     else
                       :clear
                     end
        ANSI.public_send(color_code) { str }
      end
    end

    class << self
      def logger
        @logger ||= create_logger
      end

      def log_device
        @log_device || $stdout
      end

      def log_device=(value)
        @log_device = value
        @logger = create_logger
      end
      
      private

      def create_logger
        ::Logger.new(log_device).tap do |logger|
          logger.formatter = Formatter.new
        end
      end

      def respond_to_missing?(method, include_private = false)
        logger.respond_to?(method)
      end

      def method_missing(method, *args, &block)
        logger.public_send(method, *args, &block)
      end
    end
  end
end

