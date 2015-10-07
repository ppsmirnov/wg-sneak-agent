# wg-sneak-agnet

Wg-snenk-agent - gem, that allows wg-sneak server to monitor project's Production and Rake logs. Gem also makes Rake to
log its errors and patches Production log to track user agent in some cases.
### Installation

Add this line to your application's Gemfile:

`gem "wg-sneak-agent", :git => 'git@bitbucket.org:webgears/wg-sneak-agent.git'`

### Working with gem

Gem adds 4 rake tasks:

  - sneak:create_user — creates 'log-listener' user; creates .ssh directory and authorized_keys file for this user
  - sneak:add_key — adds id_rsa.pub key from gem root directory to log-listener authorized_keys file to give wg-sneak server access to this project
  - sneak:connect — sends post request to wg-sneak server in order to add current project to log tracking
  - sneak:configure — runs all tasks listed above

 All tasks should be executed as root.