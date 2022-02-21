# frozen_string_literal: true

require "spec_helper"
require "ripcord/json_rpc/notification"

describe Ripcord::JsonRPC::Notification do
  let(:subject) { Ripcord::JsonRPC::Notification.new("track.event", { event: "register", user_id: 4711 }) }

  context "#to_payload" do
    it "generates a payload hash for given params" do
      expect(subject.to_payload).to eq({
                                         jsonrpc: "2.0",
                                         method: "track.event",
                                         params: { event: "register", user_id: 4711 }
                                       })
    end
  end
end
