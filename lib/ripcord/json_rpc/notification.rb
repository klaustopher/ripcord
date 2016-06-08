require 'ripcord/json_rpc/request'

module Ripcord::JsonRPC
  class Notification < Request
    def initialize(method, params)
      @method, @params = method, params
      @id = nil
    end
  end
end
