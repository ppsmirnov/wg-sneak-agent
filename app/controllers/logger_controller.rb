class LoggerController < ActionController::Base
  def log_js
    log = Logger.new('log/js.log')
    trace = "  #{params['details'][1]} at line #{params['details'][2]}"
    log.info("Started GET \"#{params['details'][3]}\" user-agent #{params['context']}")
    log.fatal("\n#{params['details'][0]}\n#{trace}\n")
    render nothing: true
  end
end
