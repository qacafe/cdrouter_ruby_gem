#!/usr/bin/ruby

# -- Use the CDRouter Gem to make life easy
require 'cdrouter'
require 'date'

from = CDRouter::Session.new
from.base_url     = "http://pod2.lan:8015"
from.api_token    = "c13518dc"
from.debug        = false

to = CDRouter::Session.new
to.base_url       = "http://10.0.1.179:8015"
to.api_token      = "5a21f9c7"
to.debug          = false

begin
  puts "Connecting to #{from.base_url}"
  puts "Found CDRouter version " + from.version
rescue => exception
  puts "Unable to determine the CDRouter Web API version from #{from.base_url}"
  puts "Error: " + exception.message
  exit
end

begin
  puts "Connecting to #{to.base_url}"
  puts "Found CDRouter version " + to.version
rescue => exception
  puts "Unable to determine the CDRouter Web API version from #{to.base_url}"
  puts "Error: " + exception.message
  exit
end

# -- get the last result
puts "Looking up latest results on #{from.base_url}"
results = from.results.list( :limit => 2)

# -- perform export/import
results.each do |r|

  if r.status == "running"
    next
  end
  
  # -- export with your own filename
  puts "Exporting latest result from #{from.base_url} ..."
  path = r.export_to_file

  puts "Importing #{path} from #{from.base_url} to #{to.base_url}"
  id = to.import_from_file( path )

  #puts "base is #{to.base_url}"
  #to = CDRouter::Session.new
  #to.base_url       = "http://10.0.1.179:8015"
  #to.api_token      = "5a21f9c7"
  #to.debug          = false

  #to.import_commit(id)

  exit
end


