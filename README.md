CDRouter is a Ruby gem to interact with the CDRouter Web API. 

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

    sudo gem install ./cdrouter-0.0.1.gem

## Run examples

Before running the examples, you will need to update the URL and API token
settings in the example scripts. Please set the base_url to the CDRouter
system URL. If using the CDRouter user model, you will need to specify an
API token of a user from ADMIN -> USERS on your CDRouter system.

     sess = CDRouter::Session.new
     sess.base_url     = "https://10.0.1.179"
     sess.api_token    = "5a21f9c7"

Now you can run the examples

    ./example/simple.rb


Copyright (c) 2016 QA Cafe

