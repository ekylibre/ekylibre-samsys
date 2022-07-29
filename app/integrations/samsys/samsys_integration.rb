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

    BASE_URL = 'https://app.samsys.io/api/v1'.freeze
    TOKEN_URL = BASE_URL + '/auth'.freeze
    COUNTERS_URL = BASE_URL + '/counters'.freeze
    MACHINES_URL = BASE_URL + '/machines'.freeze
    CAN_DATA_URL = BASE_URL + '/can_data'.freeze
    FIELDS_URL = BASE_URL + '/fields'.freeze

    authenticate_with :check do
      parameter :email
      parameter :password
    end

    calls :get_token, :fetch_user_info, :fetch_clusters, :get_machine, :delete_machine, :post_machines, :post_parcels, :fetch_all_counters, :fetch_all_machines, :fetch_geolocation,
          :fetch_activities_machine, :fetch_works_activity, :fetch_work_geolocations, :fetch_fields, :fetch_field

    # Get token with login and password
    # DOC https://doc.samsys.io/#api-Authentication-Authentication
    def get_token
      integration = fetch
      payload = { email: integration.parameters['email'], password: integration.parameters['password'] }
      post_json(TOKEN_URL, payload) do |r|
        r.error :api_down unless r.body.include? 'ok'
        r.success do
          list = JSON(r.body).deep_symbolize_keys
          parameters = integration.parameters
          parameters['token'] = list[:jwt]
          integration.update_columns(
            ciphered_parameters: parameters.ciphered,
            initialization_vectors: parameters.ivs
          )
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

    def fetch_clusters
      integration = fetch
      # Get token
      if integration.parameters['token'].blank?
        get_token
      end

      # Call API
      get_json("#{BASE_URL}/clusters", 'Authorization' => "JWT #{integration.parameters['token']}") do |r|
        r.success do
          list = JSON(r.body).map(&:deep_symbolize_keys)
        end
      end
    end

    # Get informations about one machine
    def get_machine(machine_id)
      integration = fetch
      # Get token
      if integration.parameters['token'].blank?
        get_token
      end
      # Call API
      get_json("#{BASE_URL}/machines/#{machine_id}", 'Authorization' => "JWT #{integration.reload.parameters['token']}") do |r|
        r.success do
          list = JSON(r.body).deep_symbolize_keys
        end
      end
    end

    # Delete one machine
    def delete_machine(machine_id)
      integration = fetch
      # Get token
      if integration.parameters['token'].blank?
        get_token
      end
      # Call API
      delete_json("#{BASE_URL}/machines/#{machine_id}", 'Authorization' => "JWT #{integration.reload.parameters['token']}") do |r|
        r.success do
          "Machine ID #{machine_id} DELETED"
        end
      end
    end

    def post_machines(name, machine_type, cluster_id, brand, model, uuid, machine_width, machine_max_speed = 30.0)
      integration = fetch
      # Get token
      if integration.parameters['token'].blank?
        get_token
      end

      machine = {
              name: name,
              machine_type: machine_type,
              cluster: cluster_id,
              brand: brand,
              model: model,
              road_count_policy: 'separate',
              tool_width: machine_width,
              max_speed: machine_max_speed,
              aux_configurations: {},
              provider: { name: 'ekylibre', uuid: uuid }
            }

      post_json("#{BASE_URL}/machines", machine, 'Authorization' => "JWT #{integration.parameters['token']}") do |r|
        r.success do
          Rails.logger.info 'CREATED MACHINE'.green
          list = JSON(r.body).deep_symbolize_keys
        end
        r.error do
          Rails.logger.info 'FAILED CREATED MACHINE'.red
          list = JSON(r.body).deep_symbolize_keys
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
          name: land_parcel_name,
          type: 'Feature',
          date: land_parcel_born,
          geometry: {
              type: 'Polygon',
              coordinates: land_parcel_coordinates
          },
          provider: { Ekylibre: land_parcel_providers }
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

      # Call API
      get_json(COUNTERS_URL, 'Authorization' => "JWT #{integration.reload.parameters['token']}") do |r|
        r.success do
          list = JSON(r.body).map(&:deep_symbolize_keys)
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
          list = JSON(r.body).map(&:deep_symbolize_keys)
        end
      end
    end

    # Get last geolocation of a machine
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
      get_html("#{MACHINES_URL}/#{machine_id}/activities?start_date=#{started_on}&end_date=#{stopped_on}",
               'Authorization' => "JWT #{integration.reload.parameters['token']}") do |r|
        r.success do
          list = JSON(r.body).map(&:deep_symbolize_keys)
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
          list = JSON(r.body).map(&:deep_symbolize_keys)
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
          list = JSON(r.body, allow_nan: true).map(&:deep_symbolize_keys)
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
          list = JSON.parse(r.body)
        end
      end
    end

    def fetch_field(id)
      integration = fetch

      get_html(FIELDS_URL + '/' + id, header(integration)) do |r|
        r.success do
          list = JSON.parse(r.body)
        end
      end
    end

    def header(integration)
      if integration.parameters['token'].blank?
        get_token
      end

      { 'Authorization' => "JWT #{integration.reload.parameters['token']}" }
    end

    # Check if the API is up
    # https://doc.samsys.io/#api-Authentication-Authentication
    def check(integration = nil)
      integration = fetch integration
      puts integration.inspect.red
      payload = { email: integration.parameters['email'], password: integration.parameters['password'] }
      post_json(TOKEN_URL, payload) do |r|
        r.success do
          list = JSON(r.body).deep_symbolize_keys
          if list[:status] == 'ok'
            puts 'check success'.inspect.green
            Rails.logger.info 'CHECKED'.green
          end
          r.error :wrong_password if list[:status] == '401'
          r.error :no_account_exist if list[:status] == '404'
        end
      end
    end

  end
end
