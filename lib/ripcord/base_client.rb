require 'securerandom'
require 'uri'
require 'net/http'
require 'json'

module Ripcord
  class BaseClient
    def generate_request_id
      SecureRandom.hex(16)
    end

    attr_accessor :authentication

    def initialize(endpoint_url)
      @endpoint_url = URI.parse(endpoint_url)
      @http_client = Net::HTTP.new(@endpoint_url.host, @endpoint_url.port)
    end

    protected
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

  end
end
