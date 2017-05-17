require File.expand_path("../lib/cdrouter/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = 'cdrouter'
  s.version     = CDRouter::VERSION
  s.date        = '2017-05-17'
  s.summary     = "CDRouter Ruby API Gem"
  s.description = "A Ruby Gem for interacting with the CDRouter REST API"
  s.authors     = ["QA Cafe"]
  s.email       = 'support@qacafe.com'
  s.files       = ["lib/cdrouter.rb", "lib/cdrouter/version.rb", "lib/cdrouter/session.rb", "lib/cdrouter/package.rb", "lib/cdrouter/config.rb", "lib/cdrouter/result.rb", "lib/cdrouter/history.rb", "lib/cdrouter/user.rb", "lib/cdrouter/device.rb" ]
  s.homepage    = 'http://www.qacafe.com'
  s.license     = 'MIT'
end
