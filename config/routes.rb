Rails.application.routes.draw do
  post 'log_js' => "logger#log_js", :as => :log_js
end
