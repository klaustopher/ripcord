require 'spec_helper'
require 'ripcord/json_rpc/response'

describe Ripcord::JsonRPC::Response do

  let(:succeeded_response) { Ripcord::JsonRPC::Response.new({ person_id: 47110815 }, nil, '1742e8634a96e9d24a1891927803127c') }
  let(:erroring_response) { Ripcord::JsonRPC::Response.new(nil, { code: -32700, message: 'Could not parse JSON' }, '1742e8634a96e9d24a1891927803127c') }

  it 'is successful when a result is present' do
    expect(succeeded_response).to be_successful
  end

  it 'is not successful when an error is present' do
    expect(erroring_response).not_to be_successful
  end

  it 'generates an error object when error is present' do
    expect(erroring_response.error).to be_kind_of(Ripcord::JsonRPC::Error)
  end

  context '.from_data' do
    it 'raises an error when the response is of the wrong JSON-RPC Version' do
      expect do
        Ripcord::JsonRPC::Response.from_data({
          jsonrpc: '1.0',
          result: { user_id: 1 },
          id: '1742e8634a96e9d24a1891927803127c'
          })
      end.to raise_error(Ripcord::Error::InvalidResponse)
    end

    it 'creates a response object from the hash' do
      response = Ripcord::JsonRPC::Response.from_data({
        jsonrpc: '2.0',
        result: { user_id: 1 },
        id: '1742e8634a96e9d24a1891927803127c'
      })

      expect(response.error).to be_nil
      expect(response.result).to eq({ user_id: 1 })
      expect(response.id).to eq('1742e8634a96e9d24a1891927803127c')
    end

  end

end
