module Ripcord::Authentication
  class HTTPTokenAuth
    def initialize(token)
      @token = token
    end

    def apply_to(request, payload_hash)
      request.add_field 'Authorization', "Token token=#{@token}"
    end
  end
end
