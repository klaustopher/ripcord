require 'spec_helper'
require 'ripcord/authentication/http_token_auth'

describe Ripcord::Authentication::HTTPTokenAuth do
  subject { described_class.new('sometoken') }

  it 'sets the correct Authorization header on the HTTP request' do
    request = double

    expect(request).to receive(:add_field).with('Authorization', 'Token token=sometoken')

    subject.apply_to(request, {})
  end
end
