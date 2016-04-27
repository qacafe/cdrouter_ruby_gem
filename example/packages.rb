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


# -- get all packages
packages = sess.packages.list

# -- sort them by test_count 
packages.sort_by!{ |x| x.test_count }.reverse!

puts "Found #{packages.count} CDRouter packages"

# -- display all packages
packages.each do |p|

  # -- look up the configuration file
  if p.config_id.to_i != 0
    config = sess.configs.get_by_id( p.config_id ).name
  else
    config = "<none>"
  end
  puts "Package #{p.name} with config #{config} has #{p.test_count} test cases"
end

