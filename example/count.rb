#!/usr/bin/ruby

# -- Use the CDRouter Gem to make life easy
require 'cdrouter'
require 'date'

#
# build a map of CDRouter systems to manage
systems = {}
systems["https://10.0.1.179"]    = { :name => "joe", :token => "5a21f9c7" }
systems["https://pod2.lan"]  = { :name => "pod2", :token => "c13518dc" }
systems["https://pod3.lan"]  = { :name => "pod3", :token => "2ec04997" }
systems["https://pod5.lan"]  = { :name => "pod5", :token => "057d8065" }
systems["https://pod6.lan"]  = { :name => "pod6", :token => "a01e946b" }
systems["https://pod7.lan"]  = { :name => "pod7", :token => "12b134cb" }
systems["https://pod8.lan"]  = { :name => "pod8", :token => "4de9b9ba" }


systems.each do |base_url, data|
  sess = CDRouter::Session.new
  sess.base_url     = base_url

  # -- use the authenticate method instead of token
  sess.authenticate('admin','cdrouter')
  #sess.api_token    = data[:token]
  
  data[:session] = sess
end

total = 0
systems.each do |base_url, data|
  sess = data[:session]
  name = data[:name]
  found = sess.results.count
  month = sess.results.count( :filter => "created>=" + (Date.today - 30 ).to_s)
  puts "system: #{name} | found #{found} results, #{month} over the last 30 days"  
  total += found
end

puts "total: found #{total} results"  

