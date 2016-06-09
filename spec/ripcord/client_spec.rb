require 'spec_helper'
require 'ripcord/client'
require 'base64'

describe Ripcord::Client do

  let(:subject) { Ripcord::Client.new('http://some-server.com/rpc-endpoint') }

  context 'initializer' do
    it 'throws an exception when the URI cannot be parsed' do
      expect { Ripcord::Client.new('§"illegal-URL§"') }.to raise_error(URI::InvalidURIError)
    end

    it 'creates the basic auth object when URL contains username and password' do
      client = Ripcord::Client.new('http://user:pass@some-server.com')
      expect(client.authentication).to be_kind_of(Ripcord::Authentication::HTTPBasicAuth)
    end
  end

  context '#call' do
    it 'creates a JsonRPC::Request with the given data and stores it as last response and calls `execute_request`' do
      expect(subject).to receive(:generate_request_id).and_return('1')

      expect(subject).to receive(:execute_request).with(Ripcord::JsonRPC::Request)
      expect(subject).to receive(:parse_response)

      subject.call('person.create', { name: 'Clark Kent'} )

      expect(subject.last_request.method).to eq('person.create')
      expect(subject.last_request.id).to eq('1')
      expect(subject.last_request.params).to eq({ name: 'Clark Kent'})
    end
  end

  context '#execute_request' do
    let(:request) { Ripcord::JsonRPC::Request.new('person.create', { name: 'Clark Kent' }, '1') }

    before(:each) do
      stub_request(:post, "http://some-server.com/rpc-endpoint")
    end

    it 'makes the correct call to the HTTP Endpoint' do
      subject.send(:execute_request, request)

      expect(WebMock).to have_requested(:post, "http://some-server.com/rpc-endpoint")
        .with(
          headers: { "Content-Type" => 'application/json' },
          body: '{"jsonrpc":"2.0","method":"person.create","params":{"name":"Clark Kent"},"id":"1"}'
        )
    end

    context 'applies authorization' do
      it 'with HTTPBasicAuth' do
        subject.authentication = Ripcord::Authentication::HTTPBasicAuth.new('user', 'password')

        subject.send(:execute_request, request)

        expect(WebMock).to have_requested(:post, "http://some-server.com/rpc-endpoint")
          .with(
            headers: { "Content-Type" => 'application/json', 'Authorization' => "Basic #{Base64.strict_encode64("user:password")}" },
            body: '{"jsonrpc":"2.0","method":"person.create","params":{"name":"Clark Kent"},"id":"1"}'
          )
      end

      it 'with HTTPTokenAuth' do
        subject.authentication = Ripcord::Authentication::HTTPTokenAuth.new('some-token')

        subject.send(:execute_request, request)

        expect(WebMock).to have_requested(:post, "http://some-server.com/rpc-endpoint")
          .with(
            headers: { "Content-Type" => 'application/json', 'Authorization' => "Token token=some-token" },
            body: '{"jsonrpc":"2.0","method":"person.create","params":{"name":"Clark Kent"},"id":"1"}'
          )
      end

      it 'with InlineToken' do
        subject.authentication = Ripcord::Authentication::InlineToken.new('some-token')

        subject.send(:execute_request, request)

        expect(WebMock).to have_requested(:post, "http://some-server.com/rpc-endpoint")
          .with(
            headers: { "Content-Type" => 'application/json' },
            body: '{"jsonrpc":"2.0","method":"person.create","params":{"name":"Clark Kent"},"id":"1","token":"some-token"}'
          )
      end
    end
  end

  context '#parse_response' do
    let(:http_response) { double(code: '200', body: '{}') }

    it 'raises an exception when a 4xx error occurs' do
      skip
    end

    it 'raises an exception when a 5xx error occurs' do
      skip
    end

    it 'wraps the JSON parse errors in an InvalidJSON expection' do
      allow(http_response).to receive(:body).and_return('{[}')

      expect do
        subject.send(:parse_response, http_response)
      end.to raise_error { |error|
        expect(error).to be_kind_of(Ripcord::Error::InvalidJSON)
        expect(error.cause).to be_kind_of(JSON::ParserError)
      }
    end

    context 'Single Response (Hash)' do
      it 'calls the `create_response_object` method with the parsed JSON' do
        allow(http_response).to receive(:body).and_return('{"jsonrpc":"2.0","result":50,"id":"1"}')
        allow(subject).to receive(:valid_json_rpc_format?).and_return(true)

        expect(subject).to receive(:create_response_object).with({jsonrpc: '2.0', result: 50, id: '1'})

        subject.send(:parse_response, http_response)
      end
    end

    context 'Batch Response (Array)' do
      it 'correctly parses an array response into an array of JsonRPC::Response objects' do
        allow(http_response).to receive(:body).and_return('[{"jsonrpc":"2.0","result":50,"id":"1"}, {"jsonrpc":"2.0","result":20,"id":"2"}]')
        allow(subject).to receive(:valid_json_rpc_format?).and_return(true)

        expect(subject).to receive(:create_response_object).once.with({jsonrpc: '2.0', result: 50, id: '1'})
        expect(subject).to receive(:create_response_object).once.with({jsonrpc: '2.0', result: 20, id: '2'})

        subject.send(:parse_response, http_response)
      end
    end
  end

  context '#valid_json_rpc_format?' do
    it 'returns false when data is not a hash' do
      expect(subject.send(:valid_json_rpc_format?, "some other data")).to be_falsey
    end

    it 'returns false when data has wrong JSONRPC version' do
      expect(subject.send(:valid_json_rpc_format?, { jsonrpc: '1.0', id: '1', result: 50 })).to be_falsey
    end

    it 'returns false when data has no id field' do
      expect(subject.send(:valid_json_rpc_format?, { jsonrpc: '2.0', result: 50 })).to be_falsey
    end

    it 'returns false when data has error and result' do
      expect(subject.send(:valid_json_rpc_format?, { jsonrpc: '2.0', id: '1', error: { code: 4711, message: 'some message' }, result: 50 })).to be_falsey
    end

    it 'returns false when data has neither error nor result' do
      expect(subject.send(:valid_json_rpc_format?, { jsonrpc: '2.0', id: '1' })).to be_falsey
    end

    it 'returns false when the error data is not a hash' do
      expect(subject.send(:valid_json_rpc_format?, { jsonrpc: '2.0', id: '1', error: 'some-error' })).to be_falsey
    end

    it 'returns false when the error data has no code' do
      expect(subject.send(:valid_json_rpc_format?, { jsonrpc: '2.0', id: '1', error: { message: 'some message' } })).to be_falsey
    end

    it 'returns false when the error code is not a number' do
      expect(subject.send(:valid_json_rpc_format?, { jsonrpc: '2.0', id: '1', error: { code: "4711", message: 'some message' } })).to be_falsey
    end

    it 'returns false when the error has no message' do
      expect(subject.send(:valid_json_rpc_format?, { jsonrpc: '2.0', id: '1', error: { code: 4711 } })).to be_falsey
    end

    it 'returns false when the error message is not a string' do
      expect(subject.send(:valid_json_rpc_format?, { jsonrpc: '2.0', id: '1', error: { code: 4711, message: { foo: 123, bar: 456} } })).to be_falsey
    end

    it 'returns true for a valid response' do
      expect(subject.send(:valid_json_rpc_format?, { jsonrpc: '2.0', id: '1', error: { code: 4711, message: "some message" } })).to be_truthy
    end

    it 'returns false when an exception occurs' do
      allow_any_instance_of(Hash).to receive(:has_key?).and_raise('some error')
      expect(subject.send(:valid_json_rpc_format?, { jsonrpc: '2.0', id: '1', error: { code: 4711, message: "some message" } })).to be_falsey
    end
  end

  context '#create_response_object' do

    context 'JSON-RPC Errors' do
      it 'handles -32700 (Parse Error) and returns a JsonRPC::Error object' do

      end

      it 'handles -32600 (Invalid Request) and returns a JsonRPC::Error object' do

      end

      it 'handles -32601 (Method not found) and returns a JsonRPC::Error object' do

      end

      it 'handles -32602 (Invalid params) and returns a JsonRPC::Error object' do

      end

      it 'handles -32603 (Internal Error) and returns a JsonRPC::Error object' do

      end

      it 'handles all application errors and returns a JsonRPC::Error object' do

      end

    end

  end


end
