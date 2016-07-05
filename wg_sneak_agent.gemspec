Gem::Specification.new do |s|
  s.name        = 'wg-sneak-agent'
  s.version     = '2.0.12'
  s.date        = '2015-09-25'
  s.summary     = "Agent of wg-sneak application"
  s.description = "Gem patches Rakefile, establishes connection with remote wg-sneak server,
    logs http requests and rake tasks result in JSON format"
  s.authors     = ["Pavel Smirnov"]
  s.email       = 'mail@example.com'
  s.files       = `git ls-files`.split("n")
  s.homepage    = 'http://example.com'
  s.license     = 'MIT'
  s.add_runtime_dependency 'request_store',
    ['~> 1.3']
end
