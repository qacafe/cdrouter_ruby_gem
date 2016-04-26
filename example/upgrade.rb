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

# -- check for existing configuration file and delete
if sess.configs.exists?("example.conf")
  sess.configs.delete("example.conf")
end

# -- create a new configuation file
config = sess.configs.create( name: "example.conf", description: "Nice config", contents: "testvar lanIp 192.168.1.1\n" )

# -- add additional testvars
config.contents += "testvar hello there\n"
config.contents += "testvar more stuff\n"

# -- save the config
config.save

# -- upgrade the config
config.upgrade

# -- save it again
config.save

if config.check?
  puts "Configuration is OKAY"
else
  puts "Configuration check failed"
  config.errors.each do |e|
    puts "lines: " + e['lines'].join(",")
    puts "error: #{e['error']}"
  end
end
