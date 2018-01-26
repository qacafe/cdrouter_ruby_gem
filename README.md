CDRouter is a Ruby gem to interact with the CDRouter Web API. For more
information on CDRouter please visit http://www.qacafe.com.

## Intro

This gem requires 'Patron' which is a Ruby HTTP client library. Patron
version 0.6.1 or newer is required. Patron builds against libcurl and
openssl. You will need to install development versions of these
libraries on your system.

https://github.com/toland/patron

## Build

Download the cdrouter gem.
    
    gem build cdrouter.gemspec

## Install

    sudo gem install ./cdrouter-0.0.9.gem

## Run examples

Before running the examples, you will need to update the URL and API token
settings in the example scripts. Please set the base_url to the CDRouter
system URL. If using the CDRouter user model, you will need to specify an
API token of a user from ADMIN -> USERS on your CDRouter system.

     sess = CDRouter::Session.new
     sess.base_url     = "https://10.0.1.179"
     sess.api_token    = "5a21f9c7"

## Connecting with username and password

Alternatively, you may connect to the API using the username and password
of the CDRouter system. The library will authenticate and automatically
set the API token for future calls.

     sess = CDRouter::Session.new
     sess.base_url     = "https://10.0.1.179"
     sess.authenticate('admin','cdrouter')
     
## Another example

The example below searches for all packages taged with "demo" and launches them.
A simple text report is displayed after each package finished. See the
jenkins.rb example for more details on how to integrate your results with
Jenkins.


``` text
#!/usr/bin/ruby

# -- Use the CDRouter Gem to make life easy
require 'cdrouter'

sess = CDRouter::Session.new
sess.base_url     = "https://10.0.1.179"
sess.debug        = false
sess.authenticate('admin','cdrouter')


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
  result = p.launch( :tags => "jenkins,tr-069", :extra_cli_args => "-testvar myvar=example")

  # -- display a text report
  result.display

end
```


Now you can explore the simple examples in the example directory

./example/simple.rb


## More resources

http://www.qacafe.com

http://support.qacafe.com/cdrouter-web-api/

Copyright (c) 2016-2018 QA Cafe
