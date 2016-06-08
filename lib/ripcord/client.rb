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
        raise Ripcord::Error::InvalidJSON.new
      end

      http_response
    end

    def generate_request_id
      SecureRandom.hex(16)
    end

    def set_basic_auth_from_url
      self.authentication = Ripcord::Authentication::HTTPBasicAuth.new(@endpoint_url.user, @endpoint_url.password)
    end
  end
end
