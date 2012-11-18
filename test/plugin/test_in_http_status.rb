require 'helper'
require 'mocha/setup'
require 'webmock/test_unit'
require 'socket'

class HttpStatusInputTest < Test::Unit::TestCase

  def setup
    Fluent::Test.setup
    @obj = Fluent::HttpStatusInput.new
    @hash = Hash.new
  end

  CONFIG = %[
    tag http.status
    url http://www.test.ad.jp
    port 80
    basic_user user
    basic_password password
    proxy_address proxy.test.jp
    proxy_port 8080
    proxy_user proxy_user
    proxy_password proxy_password
    polling_time 10s
    #params server,date
  ]

  def create_driver(conf=CONFIG)
    Fluent::Test::InputTestDriver.new(Fluent::HttpStatusInput).configure(conf)
  end

  def test_configure
    d = create_driver

    assert_equal "http.status", d.instance.tag
    assert_equal "http://www.test.ad.jp", d.instance.url
    assert_equal 80, d.instance.port
    assert_equal "user", d.instance.basic_user
    assert_equal "password", d.instance.basic_password
    assert_equal "proxy.test.jp", d.instance.proxy_address
    assert_equal "proxy_user", d.instance.proxy_user
    assert_equal "proxy_password", d.instance.proxy_password
    assert_equal 8080, d.instance.proxy_port
    assert_equal ["10s"], d.instance.polling_time
    #assert_equal ["server","date"], d.instance.params
  end

  def test_get_status
    d = create_driver
    args = {
      :url => d.instance.url,
      :port => d.instance.port,
      :proxy_address => d.instance.proxy_address,
      :proxy_port => d.instance.proxy_port,
      :proxy_user => d.instance.proxy_user,
      :proxy_password => d.instance.proxy_password,
      :params => d.instance.params
    }

    headers = {}
    headers[:headers] = {
      "server" => "Apache",
      "date" => "Sun, 18 Nov 2012 17:12:09 GMT",
      "last-modified" => "Thu, 15 Nov 2012 02:00:30 GMT",
      "etag" => "\"68c9e3-4356-3fe2b80\"",
      "accept-ranges" => "bytes",
      "content-length" => "17238",
      "content-type" => "text/html",
      "via" => "1.1 www.test.ad.jp",
      "connection" => "close"
    }

    Socket.stubs(:gethostbyname).returns(["www.test.ad.jp", [], 0, "\xC0\xA8\x00\x01"])
    WebMock.stub_request(:head, "www.test.ad.jp").to_return(:status => 200, :headers => headers[:headers])
    res_data = @obj.__send__(:get_status,@hash,args)
    res_data[:response_time] = 0.001239
    
    result_hash = {
      :url=>"http://www.test.ad.jp",
      :host=>"www.test.ad.jp", 
      :port=>80, :request_uri=>"/",
      :proxy_address=>"proxy.test.jp",
      :proxy_port=>8080,
      :code=>200,
      :message=>"",
      :class_name=>"Net::HTTPOK",
      :ipaddress=>"192.168.0.1",
      :response_time=>0.001239,
      :headers=>{
        "server"=>"Apache",
        "date"=>"Sun, 18 Nov 2012 17:12:09 GMT",
        "last-modified"=>"Thu, 15 Nov 2012 02:00:30 GMT", 
        "etag"=>"\"68c9e3-4356-3fe2b80\"",
        "accept-ranges"=>"bytes",
        "content-length"=>17238,
        "content-type"=>"text/html",
        "via"=>"1.1 www.test.ad.jp",
        "connection"=>"close"
      }
    }

    assert_equal result_hash, res_data
  end

end
