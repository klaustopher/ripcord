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
      def from_data(response_hash)
        raise Ripcord::Error::InvalidResponse.new if response_hash[:jsonrpc] != Ripcord::JSON_RPC_VERSION

        new(response_hash[:result], response_hash[:error], response_hash[:id])
      end
    end
  end
end
