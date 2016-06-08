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
      expect(subject).to receive(:generate_request_id).and_return('0859f481778bc447c8ea4c0c338fd332')

      expect(subject).to receive(:execute_request).with(Ripcord::JsonRPC::Request)
      expect(subject).to receive(:parse_response)

      subject.call('person.create', { name: 'Clark Kent'} )

      expect(subject.last_request.method).to eq('person.create')
      expect(subject.last_request.id).to eq('0859f481778bc447c8ea4c0c338fd332')
      expect(subject.last_request.params).to eq({ name: 'Clark Kent'})
    end
  end

  context '#execute_request' do
    let(:request) { Ripcord::JsonRPC::Request.new('person.create', { name: 'Clark Kent' }, '671004c7c95e279fec1e1b055ed81723') }

    before(:each) do
      stub_request(:post, "http://some-server.com/rpc-endpoint")
    end

    it 'makes the correct call to the HTTP Endpoint' do
      subject.send(:execute_request, request)

      expect(WebMock).to have_requested(:post, "http://some-server.com/rpc-endpoint")
        .with(
          headers: { "Content-Type" => 'application/json' },
          body: '{"jsonrpc":"2.0","method":"person.create","params":{"name":"Clark Kent"},"id":"671004c7c95e279fec1e1b055ed81723"}'
        )
    end

    context 'applies authorization' do
      it 'with HTTPBasicAuth' do
        subject.authentication = Ripcord::Authentication::HTTPBasicAuth.new('user', 'password')

        subject.send(:execute_request, request)

        expect(WebMock).to have_requested(:post, "http://some-server.com/rpc-endpoint")
          .with(
            headers: { "Content-Type" => 'application/json', 'Authorization' => "Basic #{Base64.strict_encode64("user:password")}" },
            body: '{"jsonrpc":"2.0","method":"person.create","params":{"name":"Clark Kent"},"id":"671004c7c95e279fec1e1b055ed81723"}'
          )
      end

      it 'with HTTPTokenAuth' do
        subject.authentication = Ripcord::Authentication::HTTPTokenAuth.new('some-token')

        subject.send(:execute_request, request)

        expect(WebMock).to have_requested(:post, "http://some-server.com/rpc-endpoint")
          .with(
            headers: { "Content-Type" => 'application/json', 'Authorization' => "Token token=some-token" },
            body: '{"jsonrpc":"2.0","method":"person.create","params":{"name":"Clark Kent"},"id":"671004c7c95e279fec1e1b055ed81723"}'
          )
      end

      it 'with InlineToken' do
        subject.authentication = Ripcord::Authentication::InlineToken.new('some-token')

        subject.send(:execute_request, request)

        expect(WebMock).to have_requested(:post, "http://some-server.com/rpc-endpoint")
          .with(
            headers: { "Content-Type" => 'application/json' },
            body: '{"jsonrpc":"2.0","method":"person.create","params":{"name":"Clark Kent"},"id":"671004c7c95e279fec1e1b055ed81723","token":"some-token"}'
          )
      end
    end
  end

  context '#parse_response' do
    let(:http_response) { double(code: '200', body: '{"jsonrpc":"2.0","result":50,"id":"671004c7c95e279fec1e1b055ed81723"}') }
  end


end
