# frozen_string_literal: true

module Ripcord
  module Authentication
    class InlineToken
      def initialize(token)
        @token = token
      end

      def apply_to(_request, payload_hash)
        payload_hash[:token] = @token
      end
    end
  end
end
