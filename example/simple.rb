#!/usr/bin/ruby

# -- Use the CDRouter Gem to make life easy
require 'cdrouter'

sess = CDRouter::Session.new
sess.base_url     = "https://10.0.1.179"
sess.api_token    = "5a21f9c7"
sess.debug        = false


begin
  puts "Connecting to #{sess.base_url}"
  puts "Found CDRouter version " + sess.version
rescue => exception
  puts "Unable to determine the CDRouter Web API version from #{sess.base_url}"
  puts "Error: " + exception.message
  exit
end

sess.packages.list( :tagged_with =>"demo").each do |p| 

  # -- launch this package and tag with "jenkins"
  result = p.launch( :tags => "jenkins,tr-069", :extra_cli_args => "-testvar myvar=example")

  # -- display a text report
  result.display

end

