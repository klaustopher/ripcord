module Ripcord
  module JsonRPC
    class Request
      attr_accessor :method, :params
      attr_reader :id

      def initialize(method, params, id)
        @method, @params, @id = method, params, id
      end

      def to_payload
        {
          jsonrpc: Ripcord::JSON_RPC_VERSION,
          method: method,
        }.tap do |payload_hash|
          payload_hash[:params] = params if should_include_params?
          payload_hash[:id] = id unless id.nil?
        end
      end

      private
      def should_include_params?
        (params.kind_of?(Array) || params.kind_of?(Hash)) && !params.empty?
      end
    end
  end
end
