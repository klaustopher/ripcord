module Ripcord::Authentication
  class HTTPBasicAuth
    def initialize(username, password)
      @username, @password = username, password
    end

    def apply_to(request, payload_hash)
      request.basic_auth(@username, @password)
    end
  end
end
