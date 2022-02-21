# frozen_string_literal: true

require "spec_helper"
require "ripcord/authentication/http_basic_auth"

describe Ripcord::Authentication::HTTPBasicAuth do
  let(:subject) { Ripcord::Authentication::HTTPBasicAuth.new("user", "password") }

  it "applies the `basic_auth` method to the HTTP request" do
    request = double

    expect(request).to receive(:basic_auth).with("user", "password")

    subject.apply_to(request, {})
  end
end
