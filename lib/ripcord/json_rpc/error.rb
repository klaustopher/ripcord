# frozen_string_literal: true

module Ripcord
  module JsonRPC
    class Error
      attr_reader :code, :message, :data

      def initialize(code, message, data)
        @code = code
        @message = message
        @data = data
      end
    end
  end
end
