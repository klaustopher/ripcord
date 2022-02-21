# frozen_string_literal: true

module Ripcord
  module Authentication
    class HTTPBasicAuth
      def initialize(username, password)
        @username = username
        @password = password
      end

      def apply_to(request, _payload_hash)
        request.basic_auth(@username, @password)
      end
    end
  end
end
