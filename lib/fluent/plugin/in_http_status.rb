require "polling"
require "net/http"
require "net/https"
require "uri" 
require "socket"

module Fluent
  class HttpStatusInput < Input
    Plugin.register_input('http_status',self)

    config_param :tag, :string
    config_param :url, :string
    config_param :port, :integer, :default => nil
    config_param :proxy_address, :string, :default => nil
    config_param :proxy_port, :integer, :default => nil
    config_param :proxy_user, :string, :default => nil
    config_param :proxy_password, :string, :default => nil
    config_param :open_timeout, :integer, :default => 10
    config_param :read_timeout, :integer, :default => 20
    config_param :params, :string, :default => nil
    config_param :polling_time, :string
    config_param :basic_user, :string, :default => nil
    config_param :basic_password, :string, :default => nil

    def configure(conf)
      super
      @params = @params.split(',').map{|str| str.strip} unless @params.nil?
      @polling_time = @polling_time.split(',').map{|str| str.strip} unless @polling_time.nil?
      raise ConfigError, "snmp: 'polling_time' parameter is required on snmp input" if !@polling_time.nil? && @polling_time.empty?
      @retry_count = 0
    end

    def starter
      Net::HTTP.version_1_2
      @starter=Thread.new{yield}
    end

    def start
      starter{@thread=Thread.new(&method(:run))}
    end

    def run
      Polling::run(@polling_time) do
        record = Hash.new
        args = {
          :url => @url,
          :port => @port,
          :proxy_address => @proxy_address,
          :proxy_port => @proxy_port,
          :proxy_user => @proxy_user,
          :proxy_password => @proxy_password,
          :params => @params
        }
        Engine.emit(@tag, Engine.now, get_status(record,args))
        break if @end_flag
      end
    rescue TypeError => ex
      $log.error "run TypeError", :error=>ex.message
      exit
    rescue => ex
      $log.error "run failed", :error=>ex.message
      sleep(10)
      @retry_count += 1
      retry if @retry_count < 30
    end

    def shutdown
      @end_flag ||= true
      @thread.run
      @thread.join
      @starter.join
    end

    private

    def get_status(hash,*args)
      args.each do |arg|
        @url = arg[:url]
        @port = arg[:port]
        @proxy_address = arg[:proxy_address]
        @proxy_port = arg[:proxy_port]
        @proxy_user = arg[:proxy_user]
        @proxy_password = arg[:proxy_password]
        @params = arg[:params]
      end

      start = Time.now

      uri = URI.parse("#{@url}:#{@port}")
      host = uri.host
      port = uri.port
      request_uri = uri.request_uri

      http = Net::HTTP.new(host,port,@proxy_address,@proxy_port,@proxy_user,@proxy_password)
      http.open_timeout = @open_timeout
      http.read_timeout = @read_timeout

      if uri.port == 443
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.verify_depth = 5
      end

      req = Net::HTTP::Head.new(request_uri)
      req.basic_auth @basic_user, @basic_password
      response = http.request(req)

      hash[:url] = url
      hash[:host] = host
      hash[:port] = port
      hash[:request_uri] = request_uri
      hash[:proxy_address] = @proxy_address if @proxy_address
      hash[:proxy_port] = @proxy_port if @proxy_port
      hash[:code] = response.code.to_i
      hash[:message] = response.message
      hash[:class_name] = response.class.name
      hostent = Socket.gethostbyname(host)
      hash[:ipaddress] = hostent[3].unpack("C4").join('.')
      hash[:headers] = Hash.new

      response.each_key{|name|
        if @params
          @params.each{|param| hash[:headers][param] = response[param] =~ /^-?\d+$/ ? response[param].to_i : response[param]}
        else
          hash[:headers][name] = response[name] =~ /^-?\d+$/ ? response[name].to_i : response[name]
        end
      }

      response_time = Time.now - start
      hash[:response_time] = response_time * 1000
      return hash
    rescue Timeout::Error => ex
      $log.error "Timeout Error : #{ex.message}"
      hash[:code] = 408
      hash[:message] = ex.message
      return hash
    rescue => ex
      $log.error ex.message
      hash[:code] = 000
      hash[:message] = ex.message
      return hash
    end

  end
end
