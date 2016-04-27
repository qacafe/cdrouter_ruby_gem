#!/usr/bin/ruby

# -- Use the CDRouter Gem to make life easy
require 'cdrouter'

# -- create a CDRouter session
sess = CDRouter::Session.new
sess.base_url        = "https://10.0.1.179"
sess.api_token       = "5a21f9c7"
sess.debug           = false

# -- create a text session
text = Patron::Session.new
text.base_url        = "http://textbelt.com"
text.timeout         = 30
text.connect_timeout = 10

# fill in your phone number here
number = "2xx475xxxx"

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
  result = p.launch( :tags => "jenkins,blah", :extra_cli_args => "-testvar myvar=example")

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

  # build text message
  message = "Package: #{result.package_name}\n"
  message += "#{result.result}\n"
  message += "PASS: #{result.pass}\n"
  message += "FAIL: #{result.fail}\n"
  message += "URL: #{sess.base_url}/results/#{result.result_id}"
  
  # build text body
  body="number=#{number}&message=#{message}"
  
  # send text as post to textbelt.com
  resp = text.post("/text",body)
  if resp.status == 200
    answer = JSON.parse(resp.body)
    if answer['success']
      puts "Text sent to #{number}"
    else
      puts "Failed to sent text to #{number}"
      puts "#{answer['message']}"
    end
  else
    puts "Unable to send text - HTTP response #{resp.status}"
  end

end

