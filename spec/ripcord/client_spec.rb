require 'spec_helper'
require 'ripcord/client'
require 'base64'

describe Ripcord::Client do
  subject { described_class.new('http://some-server.com/rpc-endpoint') }

  context 'initializer' do
    it 'throws an exception when the URI cannot be parsed' do
      expect { described_class.new('§"illegal-URL§"') }.to raise_error(URI::InvalidURIError)
    end

    it 'creates the basic auth object when URL contains username and password' do
      client = described_class.new('http://user:pass@some-server.com')
      expect(client.authentication).to be_a(Ripcord::Authentication::HTTPBasicAuth)
    end
  end

  describe '#call' do
    it 'creates a JsonRPC::Request with the given data and stores it as last response and calls `execute_request`' do
      expect(subject).to receive(:generate_request_id).and_return('1')

      expect(subject).to receive(:execute_request).with(Ripcord::JsonRPC::Request)
      expect(subject).to receive(:parse_response)

      subject.call('person.create', { name: 'Clark Kent' })

      expect(subject.last_request.method).to eq('person.create')
      expect(subject.last_request.id).to eq('1')
      expect(subject.last_request.params).to eq({ name: 'Clark Kent' })
    end
  end

  describe '#execute_request' do
    let(:request) { Ripcord::JsonRPC::Request.new('person.create', { name: 'Clark Kent' }, '1') }

    before do
      stub_request(:post, 'http://some-server.com/rpc-endpoint')
    end

    it 'makes the correct call to the HTTP Endpoint' do
      subject.send(:execute_request, request)

      expect(WebMock).to have_requested(:post, 'http://some-server.com/rpc-endpoint')
        .with(
          headers: { 'Content-Type' => 'application/json' },
          body:    '{"jsonrpc":"2.0","method":"person.create","params":{"name":"Clark Kent"},"id":"1"}'
        )
    end

    context 'applies authorization' do
      it 'with HTTPBasicAuth' do
        subject.authentication = Ripcord::Authentication::HTTPBasicAuth.new('user', 'password')

        subject.send(:execute_request, request)

        expect(WebMock).to have_requested(:post, 'http://some-server.com/rpc-endpoint')
          .with(
            headers: {
              'Content-Type'  => 'application/json',
              'Authorization' => "Basic #{Base64.strict_encode64('user:password')}"
            },
            body:    '{"jsonrpc":"2.0","method":"person.create","params":{"name":"Clark Kent"},"id":"1"}'
          )
      end

      it 'with HTTPTokenAuth' do
        subject.authentication = Ripcord::Authentication::HTTPTokenAuth.new('some-token')

        subject.send(:execute_request, request)

        expect(WebMock).to have_requested(:post, 'http://some-server.com/rpc-endpoint')
          .with(
            headers: { 'Content-Type' => 'application/json', 'Authorization' => 'Token token=some-token' },
            body:    '{"jsonrpc":"2.0","method":"person.create","params":{"name":"Clark Kent"},"id":"1"}'
          )
      end

      it 'with InlineToken' do
        subject.authentication = Ripcord::Authentication::InlineToken.new('some-token')

        subject.send(:execute_request, request)

        expect(WebMock).to have_requested(:post, 'http://some-server.com/rpc-endpoint')
          .with(
            headers: { 'Content-Type' => 'application/json' },
            body:    {
              jsonrpc: '2.0',
              method:  'person.create',
              params:  { name: 'Clark Kent' },
              id:      '1',
              token:   'some-token'
            }.to_json
          )
      end
    end
  end

  describe '#parse_response' do
    let(:http_response) { instance_double(Net::HTTPSuccess, code: 200, body: '{}') }

    it 'raises an exception when a non 2xx status code is received' do
      allow(http_response).to receive(:code).and_return(401)
      expect do
        subject.send(:parse_response, http_response)
      end.to raise_error(Ripcord::Error::InvalidResponse)
    end

    it 'wraps the JSON parse errors in an InvalidJSON expection' do
      allow(http_response).to receive(:body).and_return('{[}')

      expect do
        subject.send(:parse_response, http_response)
      end.to raise_error { |error|
        expect(error).to be_a(Ripcord::Error::InvalidJSON)
        expect(error.cause).to be_a(JSON::ParserError)
      }
    end

    context 'Single Response (Hash)' do
      it 'calls the `create_response_object` method with the parsed JSON' do
        allow(http_response).to receive(:body).and_return('{"jsonrpc":"2.0","result":50,"id":"1"}')

        expect(Ripcord::JsonRPC::Response).to receive(:from_data).with({ jsonrpc: '2.0', result: 50, id: '1' })

        subject.send(:parse_response, http_response)
      end
    end

    context 'Batch Response (Array)' do
      it 'correctly parses an array response into an array of JsonRPC::Response objects' do
        allow(http_response).to receive(:body).and_return(<<~BODY)
          [
            {"jsonrpc":"2.0","result":50,"id":"1"},
            {"jsonrpc":"2.0","result":20,"id":"2"}
          ]
        BODY

        expect(Ripcord::JsonRPC::Response).to receive(:from_data).once.with({ jsonrpc: '2.0', result: 50, id: '1' })
        expect(Ripcord::JsonRPC::Response).to receive(:from_data).once.with({ jsonrpc: '2.0', result: 20, id: '2' })

        subject.send(:parse_response, http_response)
      end
    end
  end
end
