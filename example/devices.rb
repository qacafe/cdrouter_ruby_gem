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


# -- get all devices
devices = sess.devices.list

# -- sort them by location 
devices.sort_by!{ |x| x.location }.reverse!

puts "Found #{devices.count} CDRouter devices"

# -- display all devices
devices.each do |d|

  # -- get the result count for this device
  results = d.results.count
  
  puts "Device #{d.name}, #{results} results, location: #{d.location}"
end

