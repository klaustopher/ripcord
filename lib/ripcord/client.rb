# frozen_string_literal: true

require "ripcord/authentication"
require "ripcord/json_rpc"

require "securerandom"
require "uri"
require "net/http"
require "json"
require "logger"

module Ripcord
  class Client
    attr_accessor :authentication
    attr_reader :logger, :last_request, :last_response

    def initialize(endpoint_url)
      @endpoint_url = URI.parse(endpoint_url)

      set_basic_auth_from_url if @endpoint_url.user && @endpoint_url.password

      @http_client = Net::HTTP.new(@endpoint_url.host, @endpoint_url.port)

      if @endpoint_url.is_a?(URI::HTTPS)
        @http_client.use_ssl = true
        # @http_client.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
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

    def inspect
      "#<Ripcord::Client endpoint=#{@endpoint_url}>"
    end

    private

    def execute_request(json_rpc_request)
      request = Net::HTTP::Post.new(@endpoint_url.request_uri)
      request.content_type = "application/json"

      payload_hash = json_rpc_request.to_payload

      authentication&.apply_to(request, payload_hash)

      request.body = JSON.generate(payload_hash)

      @http_client.request(request)
    end

    def parse_response(http_response)
      # Check status code
      status_code = http_response.code.to_i
      raise Ripcord::Error::InvalidResponse, http_response.body if status_code < 200 || status_code > 299

      # try to parse json
      begin
        json_data = JSON.parse(http_response.body, symbolize_names: true)
      rescue JSON::ParserError
        raise Ripcord::Error::InvalidJSON, http_response.body
      end

      case json_data
      when Hash # Handle single response
        Ripcord::JsonRPC::Response.from_data(json_data)
      when Array # Handle batch response
        json_data.map do |request_json|
          Ripcord::JsonRPC::Response.from_data(request_json)
        end
      end
    end

    def generate_request_id
      SecureRandom.hex(16)
    end

    def set_basic_auth_from_url
      self.authentication = Ripcord::Authentication::HTTPBasicAuth.new(@endpoint_url.user, @endpoint_url.password)
    end
  end
end
