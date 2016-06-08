module Ripcord
  module Authentication
    class InlineToken
      def initialize(token)
        @token = token
      end

      def apply_to(request, payload_hash)
        payload_hash[:token] = @token
      end
    end
  end
end
