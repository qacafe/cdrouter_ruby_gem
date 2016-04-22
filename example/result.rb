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

puts "Find all packages atgged with demo"
sess.packages.list(:tagged_with => "demo").each do |p|
  puts "Found package " + p.name
end

puts "Find all packages tagged with demo using filter notation"
sess.packages.list(:filter => "tags@>{demo}").each do |p|
  puts "Found package " + p.name
end

result = sess.results.get("20160414203047")
result.display

# -- export with default file name
result.export_to_file

# -- export with your own filename
result.export_to_file( "example.gz" )

# -- export csv
File.write( "example.csv", result.to_csv )
File.write( result.name + ".csv", result.to_csv )

# -- export raw logs
result.logdir_to_tgz
result.logdir_to_tgz( "example.tgz" )

# -- export jenkins style xml report
File.write( "example.xml", result.to_jenkins )
File.write( result.name + ".xml", result.to_jenkins )

count = sess.results.list.count
puts "Found #{count} results"
