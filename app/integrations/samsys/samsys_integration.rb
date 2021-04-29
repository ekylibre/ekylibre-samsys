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
    FIELDS_URL = BASE_URL + "/fields".freeze

    authenticate_with :check do
      parameter :email
      parameter :password
    end

    calls :get_token, :fetch_user_info, :post_machines, :post_parcels, :fetch_all_counters, :fetch_all_machines, :fetch_geolocation, :fetch_activities_machine, :fetch_works_activity, :fetch_work_geolocations, :fetch_fields

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

    def fetch_user_info
      integration = fetch
      # Get token
      if integration.parameters['token'].blank?
        get_token
      end

      # Call API
      get_json("#{BASE_URL}/me", 'Authorization' => "JWT #{integration.parameters['token']}") do |r|
        r.success do
          list = JSON(r.body).deep_symbolize_keys
        end
      end
    end

    # POST MACHINE
    def post_machines(machine_name, machine_born_at, machine_type, cluster_id, machine_uuid)
      integration = fetch
      # Get token
      if integration.parameters['token'].blank?
        get_token
      end

      machine = {
              "name": machine_name,
              "start_date": machine_born_at,
              "cluster": cluster_id,
              "machine_type": machine_type,
              "brand": machine_name,
              "road_count_policy": "separate",
              "aux_configurations": {},
              "provider": {"name": "Ekylibre", "uuid": machine_uuid}
            }
      
      post_json("#{BASE_URL}/machines", machine, 'Authorization' => "JWT #{integration.parameters['token']}") do |r|
        r.success do
          Rails.logger.info 'CREATED MACHINE'.green
        end
      end
    end

    def post_parcels(user_id, land_parcel_name, land_parcel_born, land_parcel_coordinates, land_parcel_providers)
      integration = fetch
      # Get token
      if integration.parameters['token'].blank?
        get_token
      end

      land_parcel = [
          {
              "name": land_parcel_name,
              "type": "Feature",
              "date": land_parcel_born,
              "geometry": {
                  "type": "Polygon",
                  "coordinates": land_parcel_coordinates
              },
              "provider": { "Ekylibre": land_parcel_providers }
          }
      ]
      
      post_json("#{BASE_URL}/users/#{user_id}/fields", land_parcel, 'Authorization' => "JWT #{integration.parameters['token']}") do |r|
        r.success do
          Rails.logger.info 'CREATED FIELD'.green
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
      get_json(COUNTERS_URL, 'Authorization' => "JWT #{integration.reload.parameters['token']}") do |r|
        r.success do
          list = JSON(r.body).map{|p| p.deep_symbolize_keys}
        end
      end
    end

    # Get all machines
    def fetch_all_machines
      integration = fetch
      # Get token
      if integration.parameters['token'].blank?
        get_token
      end
      # Call API
      get_json("#{BASE_URL}/machines", 'Authorization' => "JWT #{integration.reload.parameters['token']}") do |r|
        r.success do
          list = JSON(r.body)
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
      get_json("#{MACHINES_URL}/#{machine_id}/geolocation", 'Authorization' => "JWT #{integration.reload.parameters['token']}") do |r|
        r.success do
          list = JSON(r.body).deep_symbolize_keys
        end
      end
    end

    # Get Activities of a machine
    # DCC https://doc.samsys.io/#api-Machines-A_machine_activities
    # https://app.samsys.io/api/v1/machines/:id_machine/activities?start_date=:start_date&end_date=:end_date
    def fetch_activities_machine(machine_id,  started_on, stopped_on)
      integration = fetch

      # Get token
      if integration.parameters['token'].blank?
        get_token
      end

      # Call API
      get_html("#{MACHINES_URL}/#{machine_id}/activities?start_date=#{started_on}&end_date=#{stopped_on}", 'Authorization' => "JWT #{integration.reload.parameters['token']}") do |r|
        r.success do
          list = JSON.parse(r.body)
        end
      end
    end

    # Get Works in an Activity
    # DOC https://doc.samsys.io/#api-Activities-Get_works_in_activities
    # https://app.samsys.io/api/v1/meta_works/:id_activity
    def fetch_works_activity(activity_id)
      integration = fetch

      # Get token
      if integration.parameters['token'].blank?
        get_token
      end 

            # Call API
      get_html("#{BASE_URL}/meta_works/#{activity_id}", 'Authorization' => "JWT #{integration.reload.parameters['token']}") do |r|
        r.success do
          list = JSON.parse(r.body)
        end
      end  
    end

    # Get Geolocations Work
    # https://doc.samsys.io/#api-Works-Get_work_geolocations
    # https://app.samsys.io/api/v1/works/:id_work/geolocations
    def fetch_work_geolocations(work_id)
      integration = fetch

      # Get token
      if integration.parameters['token'].blank?
        get_token
      end  

      # Call API
       get_html("#{BASE_URL}/works/#{work_id}/geolocations", 'Authorization' => "JWT #{integration.reload.parameters['token']}") do |r|
        r.success do
          list = JSON.parse(r.body, allow_nan: true)
        end
      end       
    end

    # Get fields of user
    def fetch_fields
      integration = fetch 
      # Get Token
      if integration.parameters['token'].blank?
        get_token
      end

      # Call API
      get_html(FIELDS_URL, 'Authorization' => "JWT #{integration.reload.parameters['token']}") do |r|
        r.success do
          list = JSON(r.body).map{ |p| p.deep_symbolize_keys }
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