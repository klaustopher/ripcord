# frozen_string_literal: true

require "ripcord/error"
require "ripcord/json_rpc/error"

module Ripcord
  module JsonRPC
    class Response
      attr_reader :result, :error, :id

      def initialize(result, error, id)
        @result = result
        @id = id

        @error = Ripcord::JsonRPC::Error.new(error[:code], error[:message], error[:data]) if error
      end

      def successful?
        error.nil? && !result.nil?
      end

      class << self
        def from_data(json_data)
          raise Ripcord::Error::InvalidResponse, json_data unless valid_data?(json_data)

          new(json_data[:result], json_data[:error], json_data[:id])
        end

        def valid_data?(json_data)
          return false unless json_data.is_a?(Hash)
          return false if json_data[:jsonrpc] != Ripcord::JSON_RPC_VERSION
          return false unless json_data.key?(:id)
          return false unless json_data.key?(:error) ^ json_data.key?(:result)

          if json_data.key?(:error)
            return false unless json_data[:error].is_a?(Hash)
            return false unless json_data[:error].key?(:code)
            return false unless json_data[:error][:code].is_a?(Integer)
            return false unless json_data[:error].key?(:message)
            return false unless json_data[:error][:message].is_a?(String)
          end

          true
        rescue StandardError
          false
        end
      end
    end
  end
end
