load File.dirname(__FILE__) + '/tasks/wg-sneak-agent.rake'
require 'logger'

module RakeApplicationMixin
  def top_level
    super
  rescue SystemExit
    # Exit silently with current status
    raise
  rescue Exception => ex
    # Exit with error message
    log = Logger.new('log/rake.log')
    # log = Logger.new(STDOUT)
    trace = ex.backtrace.map {|el| el = '  ' + el}.join("\n")
    log.fatal("\n#{ex.inspect} (Arguments: #{ARGV})\n#{trace}\n")
    raise
  end
end

class Rake::Application
  prepend RakeApplicationMixin
end

module Rails
  module Rack
    class Logger < ActiveSupport::LogSubscriber
      # Add UserAgent
      def started_request_message(request)
         'Started %s "%s" for %s at %s user-agent %s' % [
          request.request_method,
          request.filtered_path,
          request.ip,
          Time.now.to_default_s,
          request.env['HTTP_USER_AGENT'] ]
      end
    end
  end
end
