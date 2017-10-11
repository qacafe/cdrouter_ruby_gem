#!/usr/bin/ruby

# -- Use the CDRouter Gem to make life easy
require 'cdrouter'
require 'date'

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

# -- Find results older than 5 years
puts "Find all results older than 5 years"
sess.results.list(:filter => "created<=" + (DateTime.now - 365 * 5).to_s).each do |r|
  puts "Found result " + r.name
  sess.results.delete( r.result_id )
end

