# Fluent::Plugin::Http::Status

Fluentd input plugin for to get the http status.

## Installation

Add this line to your application's Gemfile:

    gem 'fluent-plugin-http-status'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fluent-plugin-http-status

## Usage

Config

    <source>
      type http_status
      tag http.status
      url https://rubygems.org
      polling_time 1m

      #=== options ===
      #port 80                    
      #basic_user user            
      #basic_password pass        
      #proxy_address proxy.test.jp
      #proxy_port 8080            
      #proxy_user user            
      #proxy_password pass        
      #params server,date         
      #open_timeout 10            
      #read_timeout 20            
    </source>
    
    <match http.status>
      type stdout
    </match>

Result

    Time : 2012-11-19 03:29:29 +0900
    Tag : http.status
    Record : {"url":"https://rubygems.org","host":"rubygems.org","port":443,"request_uri":"/","code":200,"message":"OK","class_name":"Net::HTTPOK","ipaddress":"204.232.149.25","headers":{"server":"nginx/1.2.2", ...

## Copyright
Copyright (c) 2012 hiro-su
Apache Licence, Version 2.0
