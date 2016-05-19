module WgSneakAgent

  class ExceptionsMw

    def initialize(app)
      @app = app
    end

    def call(env)
      timestamp = Time.now.to_f
      begin
        resp = @app.call(env)
        env.merge!({
          "events" => RequestStore[:events]
        })
      rescue => e
        env.merge!({
          "error_name" => e.inspect,
          "error_backtrace" => e.backtrace,
          "events" => RequestStore[:events]
        })
        raise
      end

      resp # don't forget to return response
    end
  end
end
