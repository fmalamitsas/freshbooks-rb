require 'net/https'
require 'rexml/document'
require 'logger'

module FreshBooks
  class Connection
    attr_reader :account_url, :auth_token, :request_headers
    
    @@logger = Logger.new(STDOUT)
    def logger
      @@logger
    end

    def self.log_level=(level)
      @@logger.level = level
    end
    self.log_level = Logger::WARN

    def initialize(account_url, auth_token, request_headers = {})
      raise InvalidAccountUrlError.new unless account_url =~ /^[0-9a-zA-Z\-_]+\.freshbooks\.com$/
      
      @account_url = account_url
      @auth_token = auth_token
      @request_headers = request_headers
    end
    
    def call_api(method, elements = [])
       puts "#{self.class}#call_api: Creating a request with method: #{method} and elements: #{elements.inspect}"
      request = create_request(method, elements)
       puts "#{self.class}#call_api: Sending request \"#{request}\""
      self.logger.debug request
      result = post(request)
       puts "#{self.class}#call_api: Received: \"#{result}\""
      self.logger.debug result
      Response.new(result)
    end
    
  protected
    
    def create_request(method, elements = [])
      doc = REXML::Document.new '<?xml version="1.0" encoding="UTF-8"?>'
      request = doc.add_element('request')
      request.attributes['method'] = method
      
      elements.each do |element|
        # puts "Element: " + element.class.inspect
        # puts "  - " + element.inspect
        if element.kind_of?(Hash)
          element = element.to_a
        end
        key = element.first
        value = element.last
        
        if value.kind_of?(Base)
          #puts "We thinks this is a kind of base. This is the value to_xml: " + value.to_xml
          request << REXML::Document.new(value.to_xml)
          # request.add_text(REXML::Text.new( value.to_xml, false, nil, false ))
        else
          #puts "We ain't thinkin this is a kind of base. This is the key to_xml: " + key.to_s
          #puts "This is the value to_xml: " + value.to_s
          request.add_element(REXML::Element.new(key.to_s)).text = value.to_s
        end
      end
      
      doc.to_s
    end
    
    def post(request_body)
      connection = Net::HTTP.new(@account_url, 443)
      connection.use_ssl = true
      connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
      
      request = Net::HTTP::Post.new(FreshBooks::SERVICE_URL)
      request.basic_auth @auth_token, 'X'
      request.body = request_body
      request.content_type = 'application/xml'
      @request_headers.each_pair do |name, value|
        request[name.to_s] = value
      end
      
      result = connection.start  { |http| http.request(request) }
      
      if logger.debug?
        logger.debug "Request:"
        logger.debug request_body
        logger.debug "Response:"
        logger.debug result.body
      end
      
      check_for_api_error(result)
    end
    
    def check_for_api_error(result)
      return result.body if result.kind_of?(Net::HTTPSuccess)
      
      case result
      when Net::HTTPRedirection
        if result["location"] =~ /loginSearch/
          raise UnknownSystemError.new("Account does not exist")
        elsif result["location"] =~ /deactivated/
          raise AccountDeactivatedError.new("Account is deactivated")
        end
      when Net::HTTPUnauthorized
        raise AuthenticationError.new("Invalid API key.")
      when Net::HTTPBadRequest
        raise ApiAccessNotEnabledError.new("API not enabled.")
      end
      
      raise InternalError.new("Invalid HTTP code: #{result.class}")
    end
  end
end
