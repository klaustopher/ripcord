module Ripcord
  module JsonRPC
    class Error
      attr_reader :code, :message, :data

      def initialize(code, message, data)
        @code, @message, @data = code, message, data
      end
    end
  end
end
