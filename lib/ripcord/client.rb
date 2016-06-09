require 'ripcord/authentication'
require 'ripcord/json_rpc'

require 'securerandom'
require 'uri'
require 'net/http'
require 'json'
require 'logger'

module Ripcord
  class Client
    attr_accessor :authentication
    attr_reader :logger, :last_request, :last_response

    def initialize(endpoint_url)
      @endpoint_url = URI.parse(endpoint_url)

      set_basic_auth_from_url if @endpoint_url.user && @endpoint_url.password

      @http_client = Net::HTTP.new(@endpoint_url.host, @endpoint_url.port)

      # Debug code
      @http_client.set_debug_output(Logger.new($stdout))
    end

    def call(method, params)
      request = Ripcord::JsonRPC::Request.new(method, params, generate_request_id)
      @last_request = request
      http_response = execute_request(request)

      parse_response(http_response)
    end

    def logger=(logger)
      @logger = logger
      @http_client.set_debug_output(logger)
    end

    private
    def execute_request(json_rpc_request)
      request = Net::HTTP::Post.new(@endpoint_url.request_uri)
      request.content_type = 'application/json'

      payload_hash = json_rpc_request.to_payload

      if authentication
        authentication.apply_to(request, payload_hash)
      end

      request.body = JSON.generate(payload_hash)

      @http_client.request(request)
    end

    def parse_response(http_response)
      response_code = http_response.code.to_i

      # Check status code

      # try to parse json
      begin
        json_data = JSON.parse(http_response.body, symbolize_names: true)
      rescue JSON::ParserError
        raise Ripcord::Error::InvalidJSON.new(http_response.body)
      end

      if json_data.kind_of?(Hash) # Handle single response
        raise Ripcord::Error::InvalidResponse.new(json_data.inspect) unless valid_json_rpc_format?(json_data)
        create_response_object(json_data)
      elsif json_data.kind_of?(Array) # Handle batch response
        json_data.map do |request_json|
          raise Ripcord::Error::InvalidResponse.new(request_json.inspect) unless valid_json_rpc_format?(request_json)
          create_response_object(request_json)
        end
      end
    end

    def valid_json_rpc_format?(json_data)
      return false if !json_data.kind_of?(Hash)
      return false if json_data[:jsonrpc] != Ripcord::JSON_RPC_VERSION
      return false if !json_data.has_key?(:id)
      return false if !(json_data.has_key?(:error) ^ json_data.has_key?(:result))

      if json_data.has_key?(:error)
        return false if !json_data[:error].kind_of?(Hash)
        return false if !json_data[:error].has_key?(:code)
        return false if !json_data[:error][:code].kind_of?(Fixnum)
        return false if !json_data[:error].has_key?(:message)
        return false if !json_data[:error][:message].kind_of?(String)
      end

      true

    rescue
      false
    end

    def create_response_object(json_data)
    end

    def generate_request_id
      SecureRandom.hex(16)
    end

    def set_basic_auth_from_url
      self.authentication = Ripcord::Authentication::HTTPBasicAuth.new(@endpoint_url.user, @endpoint_url.password)
    end
  end
end
