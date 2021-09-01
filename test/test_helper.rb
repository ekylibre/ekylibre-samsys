require 'vcr'
require('dotenv')

Dotenv.load(File.join(EkylibreSamsys::Engine.root, ".env"))

VCR.configure do |config|
  config.allow_http_connections_when_no_cassette = false
  config.cassette_library_dir = File.expand_path('cassettes', __dir__)
  config.filter_sensitive_data('Hello') { ENV['SAMSYS_TEST_EMAIL'] }
  config.filter_sensitive_data('World') { ENV['SAMSYS_TEST_PASSWORD'] }
  config.hook_into :webmock
  config.ignore_request { ENV['DISABLE_VCR'] }
  config.ignore_localhost = true
end
