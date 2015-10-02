require 'net/http'
require "uri"
require 'rake'


task :create_user do
  puts 'creating log-listener user'
  %x(adduser --disabled-password --quiet --gecos "" log-listener)
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
  add_key = true
  f_a.each do |line|
    if line == key
      puts "This key has been already added"
      add_key = false
    else
    end
  end
  f_a.write(key) if add_key
end

task :connect do
  puts "connecting to log server"
  ip = %x{ifconfig | grep -Eo 'inet (addr:)?[^\s]+' | grep -Eo '[0-9.]+' | grep -vE '127.0.0.[0-9]+' | uniq}
  path = Dir.pwd
  if path.slit("/")[-2] == 'releases'
    name =  path.split("/")[-3]
  else
    name =  path.split("/").last
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
