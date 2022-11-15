require 'spec_helper'
require 'ripcord/authentication/inline_token'

describe Ripcord::Authentication::InlineToken do
  subject { described_class.new('sometoken') }

  it 'adds a token property to the root of the payload' do
    payload = {}
    subject.apply_to(nil, payload)

    expect(payload[:token]).to eq('sometoken')
  end
end
