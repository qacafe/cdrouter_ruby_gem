#!/usr/bin/ruby

# -- Use the CDRouter Gem to make life easy
require 'cdrouter'
require 'date'
require 'gmail'

sess = CDRouter::Session.new
sess.base_url     = "https://10.0.1.179"
sess.api_token    = "5a21f9c7"

begin
  puts "Connecting to #{sess.base_url}"
  puts "Found CDRouter version " + sess.version
rescue => exception
  puts "Unable to determine the CDRouter Web API version from #{sess.base_url}"
  puts "Error: " + exception.message
  exit
end

# -- Find imported results over the last 5 minutes
seconds = 300
results = []
entries = sess.history.list( :filter => "created>=" + (DateTime.now - (seconds/86400.0) ).to_s)

entries.each do |e|
  if e.action == "imported" && e.resource == "result"
    results.push(sess.results.get(e.id ))
  end
end

if results.count == 0
  puts "Nothing new"
  exit
else
  puts "Notify #{results.count} new results"
end


message = "NEW RESULTS!\n"
message += "Found #{results.count} new results\n"

results.each do |r|
  message += "\n"
  message += r.text_summary
end

message += "\n\n--thanks"


gmail = Gmail.connect("user@gmail.com", 'password')
email = gmail.compose do
  to "team@company.com"
  subject "New results found"
  body message
end
email.deliver!
gmail.logout
