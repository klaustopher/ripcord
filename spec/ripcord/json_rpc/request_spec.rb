require 'spec_helper'
require 'ripcord/json_rpc/request'

describe Ripcord::JsonRPC::Request do
  subject do
    described_class.new('person.create', { name: 'Clark Kent' }, '671004c7c95e279fec1e1b055ed81723')
  end

  describe '#to_payload' do
    it 'generates a payload hash for given params' do
      expect(subject.to_payload).to eq({
                                         jsonrpc: '2.0',
                                         method:  'person.create',
                                         id:      '671004c7c95e279fec1e1b055ed81723',
                                         params:  { name: 'Clark Kent' }
                                       })
    end

    it 'allows array as params' do
      subject.params = %w[foo bar]
      expect(subject.to_payload).to eq({
                                         jsonrpc: '2.0',
                                         method:  'person.create',
                                         id:      '671004c7c95e279fec1e1b055ed81723',
                                         params:  %w[foo bar]
                                       })
    end

    ['some string', 4711, 2.5, true, nil].each do |param_value|
      it "omits simple param types (#{param_value.class})" do
        subject.params = param_value

        expect(subject.to_payload).to eq({
                                           jsonrpc: '2.0',
                                           method:  'person.create',
                                           id:      '671004c7c95e279fec1e1b055ed81723'
                                         })
      end
    end
  end
end
