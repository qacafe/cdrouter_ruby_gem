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

sess.configs.list.each do |c|
  if c.check?
    puts "#{c.name} OKAY"

  else
    puts "#{c.name} FAIL"
    c.errors.each do |e|
      puts "lines: " + e['lines'].join(",")
      puts "error: #{e['error']}"
    end
    puts
    
  end
end

