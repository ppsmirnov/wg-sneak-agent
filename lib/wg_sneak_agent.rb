load File.dirname(__FILE__) + '/tasks/wg-sneak-agent.rake'

require 'wg_sneak_agent/middlewares/main_mw'
require 'wg_sneak_agent/middlewares/exceptions_mw'

require 'logger'


module RakeApplicationMixin

  def top_level
    timestamp = Time.now
    super
    write_entry(log_data(timestamp))
  rescue SystemExit
    raise
  rescue Exception => ex
    # Plain log
    log = Logger.new('log/rake.log')
    trace = ex.backtrace.map {|el| el = '  ' + el}.join("\n")
    log.fatal("\n#{ex.inspect} (Arguments: #{ARGV})\n#{trace}\n")

    # JSON log
    write_entry(log_data(timestamp, ex))
    raise
  end

  private
    def log_data(timestamp, exception=nil)
      entry = {
        logType: 'rake',
        timestamp: timestamp,
        args: ARGV,
        duration: Time.now - timestamp
      }

      if exception
        entry.merge!({
          value: exception.inspect,
          backtrace: exception.backtrace
        })
      end

      entry
    end

    def write_entry(entry)
      Rails::RAKE_LOG.write(entry.to_json + "\n")
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
      env ||= {}
      old_session = get_session
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

      env["session"] = get_session

      event.merge!({
        duration: Time.now - event[:timestamp]
      })

      RequestStore.store[:events].push(event)

      result
    end

    private
      def get_session
        begin
          session.to_hash
        rescue => e
          nil
        end
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

        result = old_log.bind(self).(sql, name, binds, statement_name, *args, &block)

        event = query_event(sql, name, binds, timestamp)
        RequestStore.store[:events].push(event) if event

        result
      end

    private
      def query_event(sql, name, binds, timestamp)

        return nil if name == 'SCHEMA'

        {
          type: 'db',
          timestamp: timestamp,
          duration: Time.now - timestamp,
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

    initializer "wg_sneak_agent.init_log_files" do
      Rails::HTTP_LOG = File.open(Rails.root.join('log', "#{Rails.env}.json.log"), 'a+')
      Rails::HTTP_LOG.sync = true
      Rails::RAKE_LOG = File.open(Rails.root.join('log', "rake.json.log"), 'a+')
      Rails::RAKE_LOG.sync = true
    end
  end
end
