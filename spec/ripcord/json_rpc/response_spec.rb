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
      expect(Ripcord::JsonRPC::Response).to receive(:valid_data?).and_return(false)
      expect do
        Ripcord::JsonRPC::Response.from_data({})
      end.to raise_error(Ripcord::Error::InvalidResponse)
    end

    it 'creates a response object from the hash' do
      response = Ripcord::JsonRPC::Response.from_data({
        jsonrpc: '2.0',
        result: { user_id: 1 },
        id: '1742e8634a96e9d24a1891927803127c'
      })

      expect(response).to be_successful
      expect(response.error).to be_nil
      expect(response.result).to eq({ user_id: 1 })
      expect(response.id).to eq('1742e8634a96e9d24a1891927803127c')
    end

    it 'creates a response object with error object from hash' do
      response = Ripcord::JsonRPC::Response.from_data({ jsonrpc: '2.0', id: '1', error: { code: -32700, message: 'An error occurred on the server while parsing the JSON text.' } })

      expect(response).not_to be_successful
      expect(response.result).to be_nil
      expect(response.error.code).to eq(-32700)
      expect(response.error.message).to eq('An error occurred on the server while parsing the JSON text.')
      expect(response.error.data).to be_nil
    end
  end

  context '.valid_data?' do
    it 'returns false when data is not a hash' do
      expect(Ripcord::JsonRPC::Response.valid_data?("some other data")).to be_falsey
    end

    it 'returns false when data has wrong JSONRPC version' do
      expect(Ripcord::JsonRPC::Response.valid_data?({ jsonrpc: '1.0', id: '1', result: 50 })).to be_falsey
    end

    it 'returns false when data has no id field' do
      expect(Ripcord::JsonRPC::Response.valid_data?({ jsonrpc: '2.0', result: 50 })).to be_falsey
    end

    it 'returns false when data has error and result' do
      expect(Ripcord::JsonRPC::Response.valid_data?({ jsonrpc: '2.0', id: '1', error: { code: 4711, message: 'some message' }, result: 50 })).to be_falsey
    end

    it 'returns false when data has neither error nor result' do
      expect(Ripcord::JsonRPC::Response.valid_data?({ jsonrpc: '2.0', id: '1' })).to be_falsey
    end

    it 'returns false when the error data is not a hash' do
      expect(Ripcord::JsonRPC::Response.valid_data?({ jsonrpc: '2.0', id: '1', error: 'some-error' })).to be_falsey
    end

    it 'returns false when the error data has no code' do
      expect(Ripcord::JsonRPC::Response.valid_data?({ jsonrpc: '2.0', id: '1', error: { message: 'some message' } })).to be_falsey
    end

    it 'returns false when the error code is not a number' do
      expect(Ripcord::JsonRPC::Response.valid_data?({ jsonrpc: '2.0', id: '1', error: { code: "4711", message: 'some message' } })).to be_falsey
    end

    it 'returns false when the error has no message' do
      expect(Ripcord::JsonRPC::Response.valid_data?({ jsonrpc: '2.0', id: '1', error: { code: 4711 } })).to be_falsey
    end

    it 'returns false when the error message is not a string' do
      expect(Ripcord::JsonRPC::Response.valid_data?({ jsonrpc: '2.0', id: '1', error: { code: 4711, message: { foo: 123, bar: 456} } })).to be_falsey
    end

    it 'returns true for a valid response with error' do
      expect(Ripcord::JsonRPC::Response.valid_data?({ jsonrpc: '2.0', id: '1', error: { code: 4711, message: "some message" } })).to be_truthy
    end

    it 'returns true for a valid response with result' do
      expect(Ripcord::JsonRPC::Response.valid_data?({ jsonrpc: '2.0', id: '1', result: 50 })).to be_truthy
    end

    it 'returns false when an exception occurs' do
      allow_any_instance_of(Hash).to receive(:has_key?).and_raise('some error')
      expect(Ripcord::JsonRPC::Response.valid_data?({ jsonrpc: '2.0', id: '1', error: { code: 4711, message: "some message" } })).to be_falsey
    end
  end


end
