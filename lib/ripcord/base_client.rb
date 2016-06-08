require 'securerandom'
require 'uri'

module Ripcord
  class BaseClient
    def generate_request_id
      SecureRandom.hex(16)
    end

    def initialize(endpoint_url)
      @endpoint_url  = URI.parse(endpoint_url)
    end
  end
end
