# frozen_string_literal: true

module Ripcord
  module Error
    class InvalidResponse < StandardError
      def initialize(response_body = nil)
        message =  "Invalid or empty response from server."
        message += "\nResponse: #{response_body}" if response_body

        super(message)
      end
    end

    class InvalidJSON < StandardError
      def initialize(response_body)
        super("Couldn't parse JSON string received from server\nResponse: #{response_body}")
      end
    end
  end
end
