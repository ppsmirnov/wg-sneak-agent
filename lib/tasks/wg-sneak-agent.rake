require 'net/http'
require "uri"
require 'rake'


task :create_user do
  puts 'creating log-listener user'
  %x(useradd log-listener -m -k "")
  %x(mkdir /home/log-listener/.ssh && chown -R log-listener:log-listener /home/log-listener/.ssh)
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
  res = %x(ifconfig)
  ip = res.split("\n\n")[0].split("\n")[1].strip.split(" ")[1].split(":").last
  path = Dir.pwd
  name =  path.split("/").last
  uri = URI('http://localhost:3000/projects')
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
