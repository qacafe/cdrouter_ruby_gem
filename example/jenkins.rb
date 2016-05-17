#!/usr/bin/ruby

# -- Use the CDRouter Gem to make life easy
require 'cdrouter'

# -- Since we may be called from Jenkins, make sure we flush output
# so you can monitor the script output from the Jenkins console
STDOUT.sync = true

# -- create a new CDRouter session
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
  result = p.launch( :tags => "jenkins", :extra_cli_args => "-testvar myvar=example")

  # -- display a text report
  result.display

  # -- create a jenkins style *.xml test report
  File.write( p.name + "_" + result.name + ".xml", result.to_jenkins )

  # -- write out a csv version
  File.write( p.name + "_" + result.name + ".csv", result.to_csv )

  # -- get the raw logs
  result.logdir_to_tgz
  
  # -- export a copy of the result for archive
  result.export_to_file
  
end

