require 'ripcord/error'
require 'ripcord/json_rpc/error'

module Ripcord::JsonRPC
  class Response
    attr_reader :result, :error, :id

    def initialize(result, error, id)
      @result, @id = result, id

      @error = Ripcord::JsonRPC::Error.new(error[:code], error[:message], error[:data]) if error
    end

    def successful?
      error.nil? && !result.nil?
    end

    class<<self
      def from_data(json_data)
        raise Ripcord::Error::InvalidResponse.new(json_data) unless valid_data?(json_data)

        new(json_data[:result], json_data[:error], json_data[:id])
      end

      def valid_data?(json_data)
        return false if !json_data.kind_of?(Hash)
        return false if json_data[:jsonrpc] != Ripcord::JSON_RPC_VERSION
        return false if !json_data.has_key?(:id)
        return false if !(json_data.has_key?(:error) ^ json_data.has_key?(:result))

        if json_data.has_key?(:error)
          return false if !json_data[:error].kind_of?(Hash)
          return false if !json_data[:error].has_key?(:code)
          return false if !json_data[:error][:code].kind_of?(Fixnum)
          return false if !json_data[:error].has_key?(:message)
          return false if !json_data[:error][:message].kind_of?(String)
        end

        true
      rescue
        false
      end
    end
  end
end
