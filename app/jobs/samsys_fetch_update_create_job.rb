class SamsysFetchUpdateCreateJob < ActiveJob::Base
  queue_as :default
  include Rails.application.routes.url_helpers

  # set default creation date older because we have no date for machine
  DEFAULT_BORN_AT = Time.new(2010, 1, 1, 10, 0, 0, '+00:00')

  # transcode Samsys machine type in Ekylibre machine nature
  TRANSCODE_MACHINE_TYPE = {
                          "micro tracteur" => :tractor, "tracteur agricole" => :tractor,
                          "tracteur de pente" => :tractor, "tracteur enjambeur" => :tractor,
                          "tracteur forestier" => :tractor, "tracteur fruitier" => :tractor,
                          "tracteur vigneron" => :tractor, "unimog" => :tractor
                            }.freeze

  MACHINE_CUSTOM_FIELDS = {
                          "model" => {name: "Modèle", customized_type: "Equipment", options: {column_name: "model_name"}},
                          "brand" => {name: "Marque", customized_type: "Equipment", options: {column_name: "brand_name"}}
                          }.freeze

  # transcode Samsys machine indicators in Ekylibre machine indicators
  MACHINE_INDICATORS = {
                          :engine_total_hours_of_operation => {indicator: :hour_counter, unit: :hour},
                          :fuel_level => {indicator: :fuel_level, unit: :percent}
                          }.freeze


  def perform
    begin
      # create custom field for all equipement if not exist
      MACHINE_CUSTOM_FIELDS.each do |key, value|
        unless cf = CustomField.find_by_name(value[:name])
          create_custom_field_for_machine(value[:name], value[:customized_type], value[:options])
        end
      end

      # Get all counter for a user
      # https://doc.samsys.io/#api-Counters-Get_all_counters_of_a_user
      Samsys::SamsysIntegration.fetch_all_counters.execute do |c|
        c.success do |list|
          list.map do |counter|
            # puts counter.inspect.green
            # counter attributes
            # counter[:id]
            # counter[:v_bat]
            # counter[:v_ext]
            # counter[:owner] {}
            # counter[:association] {} --> machine {}

            # NOTE : in Ekylibre model
            # sensor has_one sensor_equipment
            # sensor_equipment has_many localisations (in equipment)

            sensor = Sensor.find_or_create_by(
              vendor_euid: :samsys,
              model_euid: :samsys,
              euid: counter[:id],
              name: counter[:id],
              retrieval_mode: :integration
            )
            sensor.update!(
              battery_level: counter[:v_bat],
              last_transmission_at: Time.now
            )

            # find_or_create_sensor_equipment
            sensor_equipment = find_or_create_sensor_equipment(sensor, counter, c.id)

            # link the equipment to sensor
            sensor.update!(product_id: sensor_equipment.id) if sensor_equipment

            if counter[:association].any? && counter[:association][:machine].any? && sensor_equipment
              counter[:association][:machine].each do |machine|
                # Find or create an equipement corresponding to the machine
                find_or_create_machine_equipment(machine, counter, sensor_equipment, c.id)
              end
            end

          end
        end
      end
    rescue StandardError => error
      Rails.logger.error $!
      Rails.logger.error $!.backtrace.join("\n")
      ExceptionNotifier.notify_exception($!, data: { message: error })
    end
  end

  private

  def find_or_create_sensor_equipment(sensor, counter, call_id)
    # Find or create the owner
    if counter[:owner][:type_cluster] == "farm"
      owner = Entity.of_company
    elsif counter[:owner][:type_cluster] != "farm"
      #TODO create the entity
    end

    # Find the variant corresponding to geolocalisation sensor
    #TODO add sensor to Lexicon and replace electric_pruning by good reference
    sensor_variant = ProductNatureVariant.import_from_lexicon(:flatbed_trailer)

    # Find or create an equipment corresponding to the sensor
    # create the equipment
    sensor_equipments = Equipment.where('providers ->> ? = ?', 'samsys', counter[:id])
    if sensor_equipments.any?
      sensor_equipment = sensor_equipments.first
    else
      sensor_equipment = Equipment.create!(
        variant_id: sensor_variant.id,
        name: counter[:id],
        initial_born_at: sensor.created_at,
        initial_population: 1,
        initial_owner: owner,
        work_number: "SAMSYS_" + counter[:id].to_s,
        providers: {'samsys' => counter[:id], 'call_id' => call_id}
      )
    end
    sensor_equipment
  end

  def find_or_create_machine_equipment(machine, counter, sensor_equipment, call_id)
    # machine[:id]
    # machine[:name]
    # machine[:brand]
    # machine[:machine_type]
    puts machine.inspect.yellow

    # Find or create the owner
    if counter[:owner][:type_cluster] == "farm"
      owner = Entity.of_company
    elsif counter[:owner][:type_cluster] != "farm"
      #TODO create the entity
    end

    variant_to_find = TRANSCODE_MACHINE_TYPE[machine[:machine_type].downcase]
    if variant_to_find
      equipment_variant = ProductNatureVariant.import_from_lexicon(variant_to_find)
    else
      equipment_variant = ProductNatureVariant.import_from_lexicon(:tractor)
    end

    machine_equipments = Equipment.where('providers ->> ? = ?', 'samsys', machine[:id])
    if machine_equipments.any?
      machine_equipment = machine_equipments.first
    else
      machine_equipment = Equipment.create!(
        variant_id: equipment_variant.id,
        name: machine[:name],
        initial_born_at: DEFAULT_BORN_AT,
        initial_population: 1,
        initial_owner: owner,
        work_number: "SAMSYS_" + machine[:id].to_s,
        providers: {'samsys' => machine[:id], 'call_id' => call_id}
      )
    end
    cf = CustomField.find_by(column_name: "brand_name")
    machine_equipment.set_custom_value(cf, machine[:brand])

    # Get indicator from J1939 bus for a machine
    Samsys::SamsysIntegration.fetch_j1939_bus(machine[:id]).execute do |c|
      c.success do |j1939_indicators|
        if j1939_indicators[:t] != nil
          [:engine_total_hours_of_operation, :fuel_level].each do |j1939_ind|
            transcoded_indicator = MACHINE_INDICATORS[j1939_ind]
            if j1939_indicators[j1939_ind] != nil && machine_equipment.variant.has_indicator?(transcoded_indicator[:indicator])
              puts transcoded_indicator.inspect.yellow
              machine_equipment.read!(transcoded_indicator[:indicator], j1939_indicators[j1939_ind].in(transcoded_indicator[:unit]), at: j1939_indicators[:t], force: true)
            end
          end
        end
      end
    end

    # Get geolocation for a machine
    Samsys::SamsysIntegration.fetch_geolocation(machine[:id]).execute do |c|
      c.success do |geolocation|
        if machine_equipment.variant.has_indicator?(:geolocation)
          lat_lon = geolocation[:geometry][:coordinates]
          point = ::Charta.new_point(lat_lon[0], lat_lon[1]).to_ewkt
          read_at = geolocation[:properties][:t]
          machine_equipment.read!(:geolocation, point, at: read_at, force: true) if point && read_at
        end
      end
    end

    # Get fields work of a machine
    Samsys::SamsysIntegration.fetch_fields_worked(machine[:id]).execute do |c|
      c.success do |fields|
        puts fields.inspect.green
      end
      c.error do |e|
        puts e.inspect.red
      end
    end

    # Link the sensor to the machine
    # counter[:association][:id]
    # counter[:association][:start_date]
    # counter[:association][:end_date]
    if sensor_equipment && machine_equipment
      ProductLink.find_or_create_by(
        product_id: sensor_equipment.id,
        linked_id: machine_equipment.id,
        nature: "sensor",
        started_at: counter[:association][:start_date]
      )
    end
  end

  def create_custom_field_for_machine(name, customized_type, options = {})
    # create custom field
    cf = CustomField.create!(name: name, customized_type: customized_type,
                                   nature: options[:nature] || :text,
                                   column_name: options[:column_name])
    # create custom field choice if nature is choice
    if cf.choice? && options[:choices]
      options[:choices].each do |value, label|
        cf.choices.create!(name: label, value: value)
      end
    end
  end

  def error_notification_params(error)
    {
      message: 'error_during_samsys_api_call',
      level: :error,
      target_type: '',
      target_url: '',
      interpolations: {
        error_message: error
      }
    }
  end

end
