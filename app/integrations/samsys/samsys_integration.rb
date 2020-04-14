require 'rest-client'

module Samsys
  mattr_reader :default_options do
    {
      globals: {
        strip_namespaces: true,
        convert_response_tags_to: ->(tag) { tag.snakecase.to_sym },
        raise_errors: true
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
    MACHINES_URL = BASE_URL + "/machines".freeze
    CAN_DATA_URL = BASE_URL + "/can_data".freeze

    authenticate_with :check do
      parameter :email
      parameter :password
    end

    calls :get_token, :fetch_all_counters, :fetch_j1939_bus, :fetch_geolocation, :fetch_fields_worked

    # Get token with login and password
    #DOC https://doc.samsys.io/#api-Authentication-Authentication
    def get_token
      integration = fetch
      payload = {"email": integration.parameters['email'], "password": integration.parameters['password']}
      post_json(TOKEN_URL, payload) do |r|
        r.error :api_down unless r.body.include? 'ok'
        r.success do
          list = JSON(r.body).deep_symbolize_keys
          integration.parameters['token'] = list[:jwt]
          integration.save!
          Rails.logger.info 'CHECKED'.green
        end
      end
    end

    # Get all counters
    # DOC https://doc.samsys.io/#api-Counters-Get_all_counters_of_a_user
    def fetch_all_counters
      integration = fetch
      # Get token
      if integration.parameters['token'].blank?
        get_token
      end
      # for testing
      # call = RestClient::Request.execute(method: :get, url: COUNTERS_URL, headers: {Authorization: "JWT #{token}"})
      # counters = JSON.parse(call.body).map{|p| p.deep_symbolize_keys}

      # Call API
      get_json(COUNTERS_URL, 'Authorization' => "JWT #{integration.parameters['token']}") do |r|
        r.success do
          list = JSON(r.body).map{|p| p.deep_symbolize_keys}
        end

        r.redirect do
          Rails.logger.info '*sigh*'.yellow
        end

        r.error do
          Rails.logger.info 'What the fuck brah?'.red
          Rails.logger.info 'Token_missing'.red if token.blank?
        end
      end
    end

    # Get J1939 Data of a machine
    # DOC https://doc.samsys.io/#api-Machines-A_machine_j1939_data
    # https://app.samsys.io/api/v1/machines/:id_machine/j1939_data
    def fetch_j1939_bus(machine_id)
      integration = fetch

      # Get token
      if integration.parameters['token'].blank?
        get_token
      end

      # Call API
      get_json("#{MACHINES_URL}/#{machine_id}/j1939_data", 'Authorization' => "JWT #{integration.parameters['token']}") do |r|
        r.success do
          list = JSON(r.body).deep_symbolize_keys
        end

        r.redirect do
          Rails.logger.info '*sigh*'.yellow
        end

        r.error do
          Rails.logger.info 'What the fuck brah?'.red
        end
      end
    end

    #Get last geolocation of a machine
    # DOC https://doc.samsys.io/#api-Machines-A_machine_geolocation
    # https://app.samsys.io/api/v1/machines/:id_machine/geolocation
    def fetch_geolocation(machine_id)
      integration = fetch

      # Get token
      if integration.parameters['token'].blank?
        get_token
      end

      # Call API
      get_json("#{MACHINES_URL}/#{machine_id}/geolocation", 'Authorization' => "JWT #{integration.parameters['token']}") do |r|
        r.success do
          list = JSON(r.body).deep_symbolize_keys
        end

        r.redirect do
          Rails.logger.info '*sigh*'.yellow
        end

        r.error do
          Rails.logger.info 'What the fuck brah?'.red
        end
      end
    end

    # Get fields work of a machine
    # DOC https://doc.samsys.io/#api-Machines-A_machine_fields_worked_statistics
    # https://app.samsys.io/api/v1/machines/:id_machine/statistics/fields_worked?start_date=:start_date&end_date=:end_date
    def fetch_fields_worked(machine_id)
      integration = fetch

      # Get token
      if integration.parameters['token'].blank?
        get_token
      end
      stopped_on = Time.now.strftime("%FT%TZ")
      started_on = (Time.now - 30.days).strftime("%FT%TZ")
      puts "#{MACHINES_URL}/#{machine_id}/statistics/fields_worked?start_date=#{started_on}&end_date=#{stopped_on}".inspect.green
      # Call API
      get_json("#{MACHINES_URL}/#{machine_id}/statistics/fields_worked?start_date=#{started_on}&end_date=#{stopped_on}", 'Authorization' => "JWT #{integration.parameters['token']}") do |r|
        r.success do
          list = JSON(r.body).deep_symbolize_keys
        end

        r.redirect do
          Rails.logger.info '*sigh*'.yellow
        end

        r.error do
          list = JSON(r.body).deep_symbolize_keys
        end
      end
    end

    # Get CAN Data (ISOBUS) of a machine
    # DOC https://doc.samsys.io/#api-Can_data-Get_historical_can_data
    # https://app.samsys.io/api/v1/can_data?id_counter=:id_counter&id_counter=:id_counter&start_date=:start_date&end_date=:end_date&filter=:filter&filter=:filter
    def fetch_can_bus(counter_ids, started_on, stopped_on, filter)
      integration = fetch

      # Get token
      if integration.parameters['token'].blank?
        get_token
      end

      # Build params (date in iso8601(3))
      params = {
                id_counter: counter_ids,
                start_date: started_on.iso8601(3),
                end_date: stopped_on.iso8601(3),
                filter: filter
      }

      # Call API
      get_json(CAN_DATA_URL, 'Authorization' => "JWT #{integration.parameters['token']}", params => params) do |r|
        r.success do
          list = JSON(r.body).deep_symbolize_keys
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
    # https://doc.samsys.io/#api-Authentication-Authentication
    def check(integration = nil)
      integration = fetch integration
      puts integration.inspect.red
      payload = {"email": integration.parameters['email'], "password": integration.parameters['password']}
      post_json(TOKEN_URL, payload) do |r|
        r.success do
          list = JSON(r.body).deep_symbolize_keys
          if list[:status] == 'ok'
            puts "check success".inspect.green
            Rails.logger.info 'CHECKED'.green
          end
          r.error :wrong_password if list[:status] == '401'
          r.error :no_account_exist if list[:status] == '404'
        end
      end
    end

  end
end
