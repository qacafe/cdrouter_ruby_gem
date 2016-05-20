#!/usr/bin/ruby

#
# dump_config.rb
#
# This example script dumps all the CDRouter configuration files into a single directory
#

# -- Use the CDRouter Gem to make life easy

require 'cdrouter'
require 'optparse'

options = {}
OptionParser.new do |opt|
  opt.on('--dir DIRECTORY') { |o| options[:dir] = o }
end.parse!

if !options[:dir]
   raise "Please specify the output directory with --dir DIRECTORY"
end
   
Dir.mkdir(options[:dir]) unless File.exists?(options[:dir])

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

sess.configs.list.each_with_index do |c,i|
  puts "#{i} #{c.name}"
  c.save_to_file( File.join("#{options[:dir]}", "#{c.name}" )) 
end

