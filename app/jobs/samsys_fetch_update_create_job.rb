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
                          "tracteur vigneron" => :tractor, "unimog" => :tractor, "broyeur de branches" => :grinder,
                          "broyeur forestier" => :grinder, "broyeurs" => :grinder, "broyeurs d'accotement" => :grinder,
                          "broyeur de fanes" => :grinder, "broyeur de pierres" => :grinder, "broyeur à axe horizontal" => :grinder,
                          "epareuse" => :grinder, "epareuses" => :grinder, "gyrobroyeur" => :grinder,
                          "desileuse" => :silage_distributor, "ensileuse automotrice" => :forager, "ensileuse tractée" => :forager,
                          "ensileuses" => :forager, "pick-ups pour ensileuses" => :forager, "distributeur d'engrais" => :spreader,
                          "epandeur à fumier" => :spreader_trailer, "mixeur" => :spreader, "tonne à lisier" => :spreader,
                          "aligneuse" => :hay_rake, "andaineur" => :hay_rake, "autochargeuse" => :wheel_loader,
                          "enrubanneuse" => :baler, "faneur" => :hay_rake, "faneur andaineur" => :hay_rake,
                          "faucheuse" => :mower, "faucheuses conditionneuses" => :mower, "fenaison - autre" => :baler,
                          "groupeurs de balles" => :bale_collector, "matériel de manutention du fourrage" => :baler, "pirouette" => :baler,
                          "presse enrubanneuse" => :baler, "presse moyenne densité" => :baler, "presse à balles rondes" => :baler,
                          "presse haute densité" => :baler, "surélévateur" => :forklift, "toupie" => :hay_rake, 
                          "retourneuse" => :baler, "souleveuse" => :baler, "automotrice" => :tractor, "bâchage de tas" => :tractor, 
                          "intégrale" => :tractor, "arracheuses de pommes de terre" => :harvester, "butteuses" => :tractor, 
                          "matériel pommes de terre - autres" => :tractor, "planteuses de pommes de terre" => :implanter,
                          "tamiseuses" => :sieve_shaker, "moissonneuses batteuses" => :reaper, "moissonneuses batteuses - autre" => :reaper,
                          "cultivateurs à axe horizontal" => :arboricultural_cultivator, "herses alternatives" => :harrow, 
                          "herses rotatives" => :harrow, "machines à bêcher" => :harrow, "matériel d'épierrage" => :harrow, 
                          "bineuses" => :hoe, "charrues" => :plow, "chisels" => :plow, "combinés de préparation de sol" => :plow,
                          "cover crops" => :plow, "déchaumeurs" => :stubble_cultivator, "décompacteurs" => :soil_loosener,
                          "herses rigides" => :harrow, "herses étrillesRouleaux" => :harrow, "rouleau" => :roll,
                          "vibroculteurs" => :vibrocultivator, "pieton" => :employee, "pulvérisateur automoteur" => :sprayer,
                          "pulvérisateur porté" => :sprayer, "pulvérisateur trainé" => :sprayer, "autochargeuses" => :wheel_loader,
                          "autres remorques agricoles" => :trailer, "benne agricole" => :trailer, "bennes" => :trailer,
                          "bennes TP" => :trailer, "bennes à vendanges" => :grape_trailer, "bétaillères" => :trailer,
                          "plateau fourrager" => :trailer, "combinés de semis" => :sower, "semoir - autre" => :sower,
                          "semoir monograine" => :sower, "semoirs en ligne conventionnel" => :sower, 
                          "semoirs pour semis simplifié" => :sower, "telescopique" => :telescopic_handler, "camions" => :truck,
                          "citernes" => :water_bowser, "pelles" => :tractor, "VL" => :car, "VUL" => :car 
                        }.freeze

  MACHINE_CUSTOM_FIELDS = {
                          "model" => {name: "Modèle", customized_type: "Equipment", options: {column_name: "type_name"}},
                          "brand" => {name: "Marque", customized_type: "Equipment", options: {column_name: "brand_name"}}
                          }.freeze

  # transcode Samsys machine indicators in Ekylibre machine indicators
  MACHINE_INDICATORS = {
                          :engine_total_hours_of_operation => {indicator: :hour_counter, unit: :hour},
                          :fuel_level => {indicator: :fuel_level, unit: :percent}
                          }.freeze

  SAMSYS_MACHINE_TYPE = {
                          "grinder" => "Broyeurs", "silage_distributeur" => "Desileuse", "forager" => "Ensileuses", 
                          "spreader_trailer" => "Epandeur à fumier", "spreader" => "Distributeur d'engrais", "hay_rake" => "Aligneuse", 
                          "wheel_loader" => "Autochargeuse", "baler" => "Enrubanneuse", "mower" => "Faucheuse", "bale_collector" => "Groupeurs de balles", 
                          "tractor" => "Tracteur agricole", "harvester" => "Arracheuses de pommes de terre", "implanter" => "Planteuses de pommes de terre", 
                          "sleve_shaker" => "Tamiseuses", "reaper" => "Moissonneuses batteuses", "arboricultural_cultivator" => "Cultivateurs à axe horizontal", 
                          "harrow" => "Machines à bêcher", "hoe" => "Bineuses", "plow" => "Charrues", "stubble_cultivator" => "Déchaumeurs", 
                          "soil_loosener" => "Décompacteurs", "roll" => "Rouleau", "vibrocultivator" => "Vibroculteurs", "employee" => "pieton", 
                          "sprayer" => "Pulvérisateur porté", "trailer" => "Bennes", "grape_trailer" => "Bennes à vendanges", "sower" => "Semoir - autre", 
                          "telescopic_handler" => "Telescopique", "truck" => "Camions", "water_bowser" => "Citernes", "car" => "VL"
                        }.freeze

  def perform
    begin
      # create custom field for all equipement if not exist
      MACHINE_CUSTOM_FIELDS.each do |key, value|
        unless cf = CustomField.find_by_name(value[:name])
          create_custom_field_for_machine(value[:name], value[:customized_type], value[:options])
        end
      end

      # Get all parcels for a user
      Samsys::SamsysIntegration.fetch_fields.execute do |c|
        c.success do |list|
          exclude_parcels = []
          list.map do |parcel|
            parcel_shape_samsys = Charta.new_geometry(parcel)
            # If LandParcel Match with Parcel at Samsys store matching ids
            exclude_parcels << LandParcel.shape_matching(parcel_shape_samsys, 0.02).ids
          end

          # Find or Create PARCEL at SAMSYS
          Samsys::SamsysIntegration.fetch_user_info.execute do |c|
            c.success do |user|
              find_or_create_parcels_samsys(exclude_parcels.flatten.uniq, user[:id])
            end
          end
        end
      end

      # Get all counter for a user
      # https://doc.samsys.io/#api-Counters-Get_all_counters_of_a_user
      Samsys::SamsysIntegration.fetch_all_counters.execute do |c|
        c.success do |list|
          list.map do |counter|
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

            if counter[:association].any? && counter[:association][:machine].present? && sensor_equipment
              counter[:association][:machine].each do |machine|
                # Find or create an equipement corresponding to the machine
                find_or_create_machine_equipment(machine, counter, sensor_equipment, c.id)
              end
            end

          end
        end
      end

      # Create Machine at Samsys
      find_or_create_machine_equipment_samsys

      # Delete ride set without rides after synchro new parameters from Samsys
      delete_ride_sets_without_rides

    rescue StandardError => error
      Rails.logger.error $!
      Rails.logger.error $!.backtrace.join("\n")
      ExceptionNotifier.notify_exception($!, data: { message: error })
    end
  end

  private

  def delete_ride_sets_without_rides
    ride_set_empty = RideSet.select{|c| c.rides.count == 0}
    if ride_set_empty.any?
      RideSet.delete(ride_set_empty)
    end
  end

  def find_or_create_machine_equipment_samsys
    # Store machine's id and uuid at Samsys
    cluster_id = []
    machines_samsys = []
    machines_samsys_provider_ekylibre = []
    Samsys::SamsysIntegration.fetch_all_machines.execute do |c|
      c.success do |list|
        list.map do |machine|
          cluster_id << machine["cluster"]["id"]
          machines_samsys << machine["id"]
          if machine["provider"].present? && machine["provider"].has_key?("uuid")
            machines_samsys_provider_ekylibre << machine["provider"]["uuid"]
          end
        end
      end 
    end

    # Create/Post at Samsys if there are no similar provider[:id] or uuid at Ekylibre
    # Equipment variant name to find or create at Samsys
    variant_name = [
                    "grinder", "silage_distributeur", "forager", "spreader_trailer", "spreader", "hay_rake", 
                    "wheel_loader", "baler", "mower", "baler", "bale_collector", "tractor", "harvester", 
                    "implanter", "sleve_shaker", "reaper", "arboricultural_cultivator", "harrow",
                    "hoe", "plow", "stubble_cultivator", "soil_loosener", "roll", "vibrocultivator", 
                    "employee", "sprayer", "wheel_loader", "trailer", "grape_trailer", "sower", 
                    "telescopic_handler", "truck", "water_bowser", "car"
                  ]

    machine_equipments_to_create = Equipment.joins(:variant).merge(ProductNatureVariant.where(reference_name: variant_name))

    machine_equipments_to_create.each do |machine_equipment|
      unless machines_samsys.include?(machine_equipment.provider[:id]) || machines_samsys_provider_ekylibre.include?(machine_equipment.uuid)

        machine_type = SAMSYS_MACHINE_TYPE[machine_equipment.variant.reference_name.downcase]
        Samsys::SamsysIntegration.post_machines(machine_equipment.name, machine_equipment.born_at, machine_type, cluster_id.uniq.first, machine_equipment.uuid).execute

        # Once equipment is created at Samsys find it with uuid and update provider column at Ekylibre
        fetch_machine_equipment_provider = Samsys::SamsysIntegration.fetch_all_machines.execute { |c| c.success { |list| list.select { |n| !n["provider"].nil? }}}
        find_machine_equipment_samsys = fetch_machine_equipment_provider.find { |n| n["provider"]["uuid"] == machine_equipment.uuid }
        
        Equipment.find_by(uuid: machine_equipment.uuid ).update!(
          provider: { vendor: "Samsys", name: "samsys_equipment", id: find_machine_equipment_samsys["id"] }
        )
      end
    end
  end

  # Find or Create parcels at Samsys
  # We got the parcels that exclude all parcels presents at Samsys (Thanks to the ID of Parcel)
  def find_or_create_parcels_samsys(exclude_parcels, user_id)
    parcels = LandParcel.where.not(id: exclude_parcels)
    parcels.each do |land_parcel|
      Samsys::SamsysIntegration.post_parcels(user_id, land_parcel.name, land_parcel.born_at, land_parcel.initial_shape.to_rgeo.coordinates.first, land_parcel.uuid).execute
    end
  end

  def find_or_create_sensor_equipment(sensor, counter, call_id)
    # Find or create the owner
    if counter[:owner][:type_cluster] == "farm"
      owner = Entity.of_company
    elsif counter[:owner][:type_cluster] != "farm"
      #TODO create the entity
    end

    # Find the variant corresponding to geolocalisation sensor
    #TODO add sensor to Lexicon and replace electric_pruning by good reference
    sensor_variant = ProductNatureVariant.import_from_nomenclature(:geolocation_box)

    # Find or create an equipment corresponding to the sensor
    # create the equipment
    sensor_equipments = Equipment.where("provider ->> 'id' = ?", counter[:id])
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
        provider: {vendor: "Samsys", name: "samsys_sensor", id: counter[:id], data: { call_id: call_id }}
      )
    end
    sensor_equipment
  end

  def find_or_create_machine_equipment(machine, counter, sensor_equipment, call_id)
    # Find or create the owner
    if counter[:owner][:type_cluster] == "farm"
      owner = Entity.of_company
    elsif counter[:owner][:type_cluster] != "farm"
      #TODO create the entity
    end

    variant_to_find = TRANSCODE_MACHINE_TYPE[machine[:machine_type].downcase]
    if variant_to_find
      equipment_variant = ProductNatureVariant.import_from_nomenclature(variant_to_find)
    else
      equipment_variant = ProductNatureVariant.import_from_nomenclature(:tractor)
    end

    # Check if machine Ekylibre create at Samsys exist and store machine["provider"]["uuid"]. We check it with the uuid send to se column provider at Samsys
    machines_samsys_uuid_ekylibre = []
    Samsys::SamsysIntegration.fetch_all_machines.execute do |c|
      c.success do |list|
        list.map do |machine|
          if machine["provider"].present? && machine["provider"].has_key?("uuid")
            machines_samsys_uuid_ekylibre << machine["provider"]["uuid"]
          end
        end
      end
    end

    # Check if equipment exist at Ekylibre if not create it
    machine_equipments = Equipment.where("provider ->> 'id' = ?", machine[:id]) || Equipment.where(uuid: machines_samsys_uuid_ekylibre)
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
        provider: {vendor: "Samsys", name: "samsys_equipment", id: machine[:id], data: { call_id: call_id }}
      )
    end
    cf = CustomField.find_by(column_name: "brand_name")
    machine_equipment.set_custom_value(cf, machine[:brand])
    # Get geolocation for a machine
    Samsys::SamsysIntegration.fetch_geolocation(machine[:id]).execute do |c|
      c.success do |geolocation|
        # check if a machine geolocation is nil
        if !geolocation[:geometry][:coordinates].nil?
          if machine_equipment.variant.has_indicator?(:geolocation)
            lat_lon = geolocation[:geometry][:coordinates]
            point = ::Charta.new_point(lat_lon[1], lat_lon[0]).to_ewkt
            read_at = geolocation[:properties][:t]
            machine_equipment.read!(:geolocation, point, at: read_at, force: true) if point && read_at
          end
        end
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

    stopped_on = Time.now.strftime("%FT%TZ")
    started_on = (Time.now - 250.days).strftime("%FT%TZ")

    # Get all activities of machine, we can have multiple roads and works
    Samsys::SamsysIntegration.fetch_activities_machine(machine[:id], started_on, stopped_on).execute do |c|
      c.success do |list|
        list.sort_by{|h| h[:start_date]}.reverse.map do |activity|
          # Find or create Ride Set (Equivalent of activity at Samsys )
          ride_sets = RideSet.where("provider ->> 'id' = ?", activity["id"])
          if ride_sets.any?
            ride_set = ride_sets.first
            # Create all rides linked to a Ride Set
            create_ride(activity["id"], machine_equipment, ride_set.id)
          else
            ride_set = RideSet.create!(
              started_at: activity["start_date"],
              stopped_at: activity["end_date"],
              road: activity["road"],
              nature: activity["type"],
              sleep_count: activity["sleep_count"],
              duration: activity["duration"].to_i.seconds,
              sleep_duration: activity["sleep_duration"].to_i.seconds,
              area_without_overlap: activity["area_without_overlap"],
              area_with_overlap: activity["area_with_overlap"],
              area_smart: activity["area_smart"],
              gasoline:activity["gasoline"],
              provider: {vendor: "Samsys", name: "samsys_ride_set", id: activity["id"]}
            )

            # Create all rides linked to a Ride Set
            create_ride(activity["id"], machine_equipment, ride_set.id)
          end
        end
      end
    end
  end

  # Create a ride 
  def create_ride(activity_id, machine_equipment, ride_set_id)
    Samsys::SamsysIntegration.fetch_works_activity(activity_id).execute do |c|
      c.success do |list| 
        list.map do |work|
          # Find or create a Ride
          rides = Ride.where("provider ->> 'id' = ?", work["id"])
          if rides.any?
            ride = rides.first
            # Update ride's ride_set_id with new id from samsys's update
            ride.update!(ride_set_id: ride_set_id) if ride.ride_set_id != ride_set_id
            create_crumb_for_work_geolocations(work["id"], ride.id)
            create_crumb_for_works_geolocation_break(work["breaks"], ride.id)
          else
            ride = Ride.create!(
              started_at: work["start_date"],
              stopped_at: work["end_date"],
              duration: work["duration"].to_i.seconds,
              sleep_count: work["sleep_count"],
              sleep_duration: work["sleep_duration"].to_i.seconds,
              equipment_name: machine_equipment.name,
              state: "unaffected",
              nature: work["type"],
              distance_km: work["distance_km"],
              provider: {vendor: "Samsys", name: "samsys_ride", id: work["id"]},
              area_without_overlap: work["area_without_overlap"],
              area_with_overlap: work["area_with_overlap"],
              area_smart: work["area_smart"],
              gasoline: work["gasoline"],
              product_id: machine_equipment.id,
              ride_set_id: ride_set_id
            )

            # create crumb "point/hard_start/hard_stop" from work geolocations
            create_crumb_for_work_geolocations(work["id"], ride.id)

            # create crumb "pause" work["breaks"]
            create_crumb_for_works_geolocation_break(work["breaks"], ride.id)
          end
        end
      end
    end
  end

  # Create crumb for work geolocations
  # To get all the points of the road /work 
  def create_crumb_for_work_geolocations(work_id, ride_id)
    Samsys::SamsysIntegration.fetch_work_geolocations(work_id).execute do |c| 
      c.success do |list| 
        crumbs_all = []
        list.map do |crumb|
          crumbs_all.push(crumb)
        end

        crumbs_all_sort = crumbs_all.sort_by {|c| c["properties"]["t"]}
        crumbs_all_sort.each_with_index do |crumb, index|
          # Find or create crumb 
          crumbs = Crumb.where("provider ->> 'id' = ?", crumb["id_data"]).where(ride_id: ride_id)
          if crumbs.any?
            crumbs.first
          else
            lat_lon = crumb["geometry"]["coordinates"]
            geolocation_crumb = Charta.new_point(lat_lon[1], lat_lon[0]).to_rgeo
            nature_crumb = if index == 0 
                            "hard_start"
                          elsif index == (crumbs_all_sort.length - 1)
                            "hard_stop"
                          else
                            "point"
                          end

            crumb = Crumb.create!(
              nature: nature_crumb,
              device_uid: "samsys",
              accuracy: 4,
              geolocation: geolocation_crumb,
              read_at: crumb["properties"]["t"],
              metadata: {'speed' => crumb["properties"]["speed"]},
              provider: {vendor: "Samsys", name: "samsys_crumb", id: crumb["id_data"]},
              ride_id: ride_id
            )

          end
        end
      end
    end
  end

  # Create crumb for works geolocation stop/pause
  # To get geolocation breaks
  def create_crumb_for_works_geolocation_break(breaks, ride_id)
    breaks.each do |break_c|
      # Find or create crumb 
      crumbs = Crumb.where("provider ->> 'id' = ?", break_c["start_date"])
      if crumbs.any?
        crumb = crumbs.first
      else
        lat_lon = break_c["geometry"]["coordinates"]
        geolocation_break = Charta.new_point(lat_lon[1], lat_lon[0]).to_rgeo

        crumb = Crumb.create!(
          nature: "pause",
          device_uid: "samsys",
          accuracy: 4,
          geolocation: geolocation_break,
          read_at: break_c["start_date"],
          metadata: {'duration' => break_c["duration"], 'start_date' => break_c["start_date"], 'end_date' => break_c["end_date"]},
          provider: {vendor: "Samsys", name: "samsys_crumb_break", id: break_c["start_date"]},
          ride_id: ride_id
        )

      end
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
