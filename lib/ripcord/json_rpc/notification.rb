require 'ripcord/json_rpc/request'

module Ripcord
  module JsonRPC
    class Notification < Request
      def initialize(method, params)
        @method = method
        @params = params
        @id = nil
      end
    end
  end
end
