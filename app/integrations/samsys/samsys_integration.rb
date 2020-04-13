require 'rest-client'

module Samsys
  mattr_reader :default_options do
    {
      globals: {
        strip_namespaces: true,
        convert_response_tags_to: ->(tag) { tag.snakecase.to_sym },
        raise_errors: false
      },
      locals: {
        advanced_typecasting: true
      }
    }
  end

  class ServiceError < StandardError; end

  class SamsysIntegration < ActionIntegration::Base
    # Set url needed for Samsys API v2

    BASE_URL = "https://app.samsys.io/api/v1".freeze
    TOKEN_URL = BASE_URL + "/auth".freeze
    COUNTERS_URL = BASE_URL + "/counters".freeze

    authenticate_with :check do
      parameter :email
      parameter :password
    end

    calls :get_token, :fetch_all_counters

    # Get token with login and password
    def get_token
      integration = fetch

      # for testing
      # call = RestClient.post url: TOKEN_URL, {email: email, password: password}
      # token = JSON(call.body).deep_symbolize_keys[:jwt]

      payload = {"email": integration.parameters['email'], "password": integration.parameters['password']}
      post_json(TOKEN_URL, payload) do |r|
        r.success do
          list = JSON(r.body).deep_symbolize_keys
          r.error :api_down unless r.body.include? 'ok'
        end
      end
    end

    # Get all counters
    def fetch_all_counters
      integration = fetch
      # Grab token
      token = JSON(get_token.body).deep_symbolize_keys[:jwt]

      # for testing
      # call = RestClient::Request.execute(method: :get, url: COUNTERS_URL, headers: {Authorization: "JWT #{token}"})
      # counters = JSON.parse(call.body).map{|p| p.deep_symbolize_keys}

      # Call API
      get_json(COUNTERS_URL, 'Authorization' => "JWT #{token}") do |r|
        r.success do
          list = JSON(r.body).map{|p| p.deep_symbolize_keys}
        end

        r.redirect do
          Rails.logger.info '*sigh*'.yellow
        end

        r.error do
          Rails.logger.info 'What the fuck brah?'.red
        end
      end
    end

    # Check if the API is up
    # TODO where to store token ?
    def check(integration = nil)
      integration = fetch integration
      payload = {"email": integration.parameters['email'], "password": integration.parameters['password']}
      post_json(TOKEN_URL, payload) do |r|
        r.success do
          Rails.logger.info 'CHECKED'.green
          r.error :api_down unless r.body.include? 'ok'
        end
      end
    end

  end
end
