$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'webmock/rspec'
WebMock.disable_net_connect!(allow_localhost: true)

require 'ripcord'

require 'simplecov'

SimpleCov.start do
  if ENV['CI']
    require 'simplecov-lcov'

    SimpleCov::Formatter::LcovFormatter.config do |c|
      c.report_with_single_file = true
      c.single_report_path = 'coverage/lcov.info'
    end

    formatter SimpleCov::Formatter::LcovFormatter
  end

  add_filter %w[version.rb]
end
