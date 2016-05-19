load File.dirname(__FILE__) + '/tasks/wg-sneak-agent.rake'

require 'wg_sneak_agent/middlewares/main_mw'
require 'wg_sneak_agent/middlewares/exceptions_mw'

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


module AbstractController
  class Base
    old_process = instance_method(:process)

    define_method(:process) do |action, *args|
      RequestStore.store[:events] ||= []
      old_session = session.to_hash
      event = {
        type: 'action',
        value: "#{self.class}\##{action}",
        timestamp: Time.now
      }
      begin
        result = old_process.bind(self).(action, *args)
      rescue => e
        env["session"] = old_session
        raise
      end

      env["session"] = session.to_hash

      event.merge!({
        duration: Time.now - event[:timestamp]
      })

      RequestStore.store[:events].push(event)

      result
    end
  end
end


module ActiveRecord
  module ConnectionAdapters
    class AbstractAdapter
      old_log = instance_method(:log)

      define_method(:log) do |sql, name = "SQL", binds = [], statement_name = nil, *args, &block|
        RequestStore.store[:events] ||= []
        timestamp = Time.now

        result = old_log.bind(self).(sql, name = "SQL", binds, statement_name = nil, *args, &block)

        event = query_event(sql, name, binds, timestamp)
        RequestStore.store[:events].push(event) if event

        result
      end

    private
      def query_event(sql, name, binds, timestamp)
        return nil if name == 'SCHEMA'

        {
          type: 'DB query',
          timestamp: timestamp,
          duration: Time.now - timestamp,
          name: name,
          query: sql,
          binds: binds.map{|arr| [arr.first.name, arr.second]}
        }
      end

    end
  end
end


module WgSneakAgent
  class Engine < Rails::Engine
  end
  class Railtie < ::Rails::Railtie
    initializer "wg_sneak_agent.insert_middleware" do |app|
      app.config.middleware.insert_before 0, WgSneakAgent::MainMw
      app.config.middleware.insert_after ActionDispatch::DebugExceptions, WgSneakAgent::ExceptionsMw
    end
  end
end
