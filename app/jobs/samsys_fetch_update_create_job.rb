class SamsysFetchUpdateCreateJob < ActiveJob::Base
  queue_as :default
  include Rails.application.routes.url_helpers

  # set default creation date older because we have no date for machine
  DEFAULT_BORN_AT = Time.new(2010, 1, 1, 10, 0, 0, '+00:00')

  # transcode Samsys machine type in Ekylibre machine nature
  TO_EKYLIBRE_MACHINE_TYPE = {
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

  TO_SAMSYS_MACHINE_TYPE = {
                          "air_compressor" => "Tracteur agricole", "animal_housing_cleaner" => "Tracteur agricole", "bale_collector" => "Matériels manutention du fourrage", 
                          "baler" => "Matériels manutention du fourrage", "chainsaw" => "Broyeur de branches", "complete_sower" => "Combinés de semis", 
                          "corn_topper" => "Broyeur à axe horizontal", "cover_implanter" => "Cover crops", "dumper" => "Benne agricole", "ferry" => "Benne agricole", 
                          "food_distributor" => "Desileuse", "forager" => "Ensileuses", "forklift" => "Surélévateur", "gas_engine" => "Tracteur agricole",
                          "grape_reaper" => "Tracteur enjambeur", "grape_trailer" => "Bennes à vendanges", "grinder" => "Broyeurs", 
                          "harrow" => "Herses rotatives", "harvester" => "Tracteur enjambeur", "hay_rake" => "Andaineur", "hedge_cutter" => "Epareuse", 
                          "hiller" => "Combinés de préparation du sol", "hoe" => "Combinés de préparation du sol", "hoe_weeder" => "Combinés de préparation du sol", 
                          "implanter" => "Combinés de préparation du sol", 
                          "mower" => "Matériels manutention du fourrage", "picker" => "Tracteur agricole", "plow" => "Charrues", "plum_reaper" => "Tracteur agricole", 
                          "pollinator" => "Tracteur agricole", "pruning_platform" => "Tracteur agricole", "reaper" => "Moissonneuses batteuses", "roll" => "Combinés de préparation du sol",
                          "seedbed_preparator" => "Combinés de préparation du sol", "shell_fruit_reaper" => "Tracteur agricole", "sieve_shaker" => "Tamiseuses", 
                          "soil_loosener" => "Décompacteurs", "sower" => "Combinés de semis", "sprayer" => "Pulvérisateur porté", "spreader" => "Distributeur d'engrais", 
                          "spreader_trailer" => "Epandeur à fumier", "steam_engine" => "Tracteur agricole", "superficial_plow" => "Déchaumeurs", "telescopic_handler" => "Telescopique", 
                          "topper" => "Broyeur de fanes", "tractor" => "Tracteur agricole", "trailer" => "Remorque", "trimmer" => "Broyeur de branches", "truck" => "Camions",
                          "uncover" => "Tracteur agricole", "weeder" => "Tracteur agricole", "wheel_loader" => "Tracteur agricole"
                        }.freeze

  VENDOR = 'samsys'.freeze

  def perform
    begin
      # create custom field for all equipement if not exist
      machine_custom_fields = Integrations::Samsys::Handlers::MachineCustomFields.new(machine_custom_fields: MACHINE_CUSTOM_FIELDS)
      machine_custom_fields.bulk_find_or_create

      # Create CultivableZones at Samsys
      Integrations::Samsys::Handlers::CultivablesZonesAtSamsys.new.create_cultivables_zones_at_samsys

      # Get all counter for a user
      sensors = Integrations::Samsys::Handlers::Sensors.new(vendor: VENDOR)
      sensors.bulk_find_or_create

      # Create RideSets
      ride_sets = Integrations::Samsys::Handlers::RideSets.new(to_ekylibre_machine_type: TO_EKYLIBRE_MACHINE_TYPE, default_born_at: DEFAULT_BORN_AT, vendor: VENDOR)
      ride_sets.bulk_find_or_create

      # Create Machine at Samsys // Disabled method for now
      # find_or_create_machine_equipment_samsys

      # Delete ride set without rides after synchro new parameters from Samsys
      #delete_ride_sets_without_rides

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

    machine_equipments_to_create = Equipment.joins(:variant).merge(ProductNatureVariant.where(reference_name: TO_SAMSYS_MACHINE_TYPE.keys))

    machine_equipments_to_create.each do |machine_equipment|
      unless machines_samsys.include?(machine_equipment.provider[:id]) || machines_samsys_provider_ekylibre.include?(machine_equipment.uuid)

        machine_type = TO_SAMSYS_MACHINE_TYPE[machine_equipment.variant.reference_name.downcase]
        Samsys::SamsysIntegration.post_machines(machine_equipment.name, machine_equipment.born_at, machine_type, cluster_id.uniq.first, machine_equipment.uuid).execute

        # Once equipment is created at Samsys find it with uuid and update provider column at Ekylibre
        fetch_machine_equipment_provider = Samsys::SamsysIntegration.fetch_all_machines.execute { |c| c.success { |list| list.select { |n| !n["provider"].nil? }}}
        find_machine_equipment_samsys = fetch_machine_equipment_provider.find { |n| n["provider"]["uuid"] == machine_equipment.uuid }

        if find_machine_equipment_samsys.present?
          Equipment.find_by(uuid: machine_equipment.uuid ).update!(
            provider: { vendor: "Samsys", name: "samsys_equipment", id: find_machine_equipment_samsys["id"] }
          )
        end
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
