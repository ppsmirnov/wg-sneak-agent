# wg-sneak-agnet

Wg-snenk-agent - gem, that allows to track project's Production and Rake logs from wg-sneak server. Gem also makes Rake to
log it's errors and patches Production log to track user agent in some errors
### Installation

Add this line to your application's Gemfile:

`gem "wg-sneak-agent", :git => 'git@bitbucket.org:webgears/wg-sneak-agent.git'`

### Working with gem

Gem adds 4 rake tasks:

  - create_user : creates 'log-listener' user, creates .ssh directory and authorized_keys file for this user
  - add_key : adds id_rsa.pub key from gem root directory to log-listener authorized_keys file to give wg-sneak access to this project
  - connect : sends post request to wg-sneak server in order to add current project to log tracking
  - configure : runs all tasks listed above

 All tasks should be run as root