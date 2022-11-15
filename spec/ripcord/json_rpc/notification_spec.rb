require 'spec_helper'
require 'ripcord/json_rpc/notification'

describe Ripcord::JsonRPC::Notification do
  subject { described_class.new('track.event', { event: 'register', user_id: 4711 }) }

  describe '#to_payload' do
    it 'generates a payload hash for given params' do
      expect(subject.to_payload).to eq({
                                         jsonrpc: '2.0',
                                         method:  'track.event',
                                         params:  { event: 'register', user_id: 4711 }
                                       })
    end
  end
end
