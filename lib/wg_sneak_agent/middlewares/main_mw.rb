
module WgSneakAgent

  class MainMw

    def initialize(app)
      @app = app
    end

    def call(env)
      resp = @app.call(env)
      env.merge!({"timestamp" => Time.now.to_f})
      resp = set_user_id(env, resp)
      entry = env["error_name"] ? log_data(env, resp).merge(error_data(env)) : log_data(env, resp)
      write_entry(entry)
      resp
    end

    private
      def log_data(env, resp)
        {
          logType: 'http',
          status: resp.first,
          timestamp: env["timestamp"],
          duration: Time.now.to_f - env["timestamp"],
          responseHeaders: resp.second,
          method: env["REQUEST_METHOD"],
          requestHeaders: request_headers(env),
          ip: env["REMOTE_ADDR"],
          uri: env["REQUEST_URI"],
          params: request_params(env),
          events: env["events"],
          userId: env["user_id"],
          session: env["session"]
        }
      end


      def error_data(env)
        {
          errorDesc: env["error_name"],
          backtrace: env["error_backtrace"]
        }
      end

      def set_user_id(env, resp)
        cookie = request_headers(env)["Cookie"]

        if cookie && cookie.include?("_wg_sneak_user")
          timestamp = cookie.match(/_wg_sneak_user=([\d.]+)/)[0]
        else
          timestamp = Time.now.to_f
          resp.second["Set-Cookie"] = "_wg_sneak_user=#{timestamp}; Path=/"
        end

        env.merge!({
          "user_id" => timestamp
        })

        resp
      end

      def request_params(env)
        return nil unless env['action_dispatch.request.parameters']

        env['action_dispatch.request.parameters'].map do |k, v|
          if k.include?('password')
            [k, "<removed>"]
          elsif v.class == ActionDispatch::Http::UploadedFile
            [k, "__file\r\n#{v.headers}Size: #{v.size}"]
          else
            [k, v]
          end
        end.to_h
      end

      def request_headers(env)
        env.select {|k,v| k.start_with?('HTTP')}
            .collect do |key, val|
              new_key = key.sub(/^HTTP_/, '').split('_').map {|v| v.capitalize}.join('-')
              if new_key == 'Cookie'
                new_val = val.gsub(/(_.*session=[%\w-]+);?/, '')
              else
                new_val = val
              end
              [new_key, new_val]
            end.to_h
      end

      def write_entry(entry)
        p entry
        File.open(Rails.root.join('log', "#{Rails.env}.json.log"), 'a+') do |f|
          f.write(entry.to_json + "\n")
        end
      end
  end
end
