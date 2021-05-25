# frozen_string_literal: true

module Samsys
  module Handlers
    class MachinesEquipments
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

      # set default creation date older because we have no date for machine
      DEFAULT_BORN_AT = Time.new(2010, 1, 1, 10, 0, 0, '+00:00')

      VENDOR = ::Samsys::Handlers::VENDOR
      
      def bulk_find_or_create(machine, sensor_equipment)
        machine_equipment = find_or_create_machine_equipment(machine)

        custom_field = CustomField.find_by(column_name: "brand_name")
        machine_equipment.set_custom_value(custom_field, machine[:brand])

        # Get geolocation for a machine
        machine_geolocation(machine[:id], machine_equipment)
    
        # Link the sensor to the machine
        link_sensor_to_machine(sensor_equipment, machine_equipment, machine)

        machine_equipment
      end

      private 

      def find_or_create_machine_equipment(machine)
        machine_equipment = Equipment.of_provider_vendor(VENDOR).of_provider_data(:id, machine[:id].to_s).first
        
        if machine_equipment.present?
          update_machine_equipment_provider(machine_equipment, machine)
          machine_equipment
          
        else
          create_machine_equipment(machine)
        end    
      end

      def create_machine_equipment(machine)
        owner = owner_entity(machine)
        equipment_variant = variant_to_find(TO_EKYLIBRE_MACHINE_TYPE, machine[:machine_type])

        machine_equipment = Equipment.create!(
          variant_id: equipment_variant.id,
          name: machine[:name],
          initial_born_at: DEFAULT_BORN_AT,
          initial_population: 1,
          initial_owner: owner,
          work_number: "SAMSYS_#{machine[:id]}",
          provider: { vendor: VENDOR, name: "samsys_equipment", data: { id: machine[:id], tool_width: machine[:tool_width] } }
        )
      end

      def update_machine_equipment_provider(machine_equipment, machine)
        if machine_equipment.provider[:data]["tool_width"] != machine[:tool_width]
          machine_equipment.update!(provider: { 
            vendor: VENDOR,
            name: "samsys_equipment", 
            data: { id: machine[:id], tool_width: machine[:tool_width] } 
          }) 
        end
      end

      def owner_entity(machine)
        if machine[:cluster][:type_cluster] == "farm"
          Entity.of_company
        elsif machine[:cluster][:type_cluster] != "farm"
          #TODO create the entity
        end
      end

      def variant_to_find(to_ekylibre_machine_type, machine_type)
        variant_to_find = to_ekylibre_machine_type[machine_type.downcase]

        if variant_to_find
          ProductNatureVariant.import_from_nomenclature(variant_to_find)
        else
          ProductNatureVariant.import_from_nomenclature(:tractor)
        end
      end

      def machine_geolocation(machine_id, machine_equipment)
        machine_geolocation = ::Samsys::Data::MachineGeolocation.new(machine_id: machine_id).result
        if machine_geolocation[:geometry][:coordinates].present? && machine_equipment.variant.has_indicator?(:geolocation)
          lat_lon = machine_geolocation[:geometry][:coordinates]
          point = ::Charta.new_point(lat_lon[1], lat_lon[0]).to_ewkt
          read_at = machine_geolocation[:properties][:t]
          machine_equipment.read!(:geolocation, point, at: read_at, force: true) if point && read_at
        end
      end

      def link_sensor_to_machine(sensor_equipment, machine_equipment, machine)
        if sensor_equipment && machine_equipment
          ProductLink.find_or_create_by(
            product_id: sensor_equipment.id,
            linked_id: machine_equipment.id,
            nature: "sensor",
            started_at: machine[:associations].first[:start_date]
          )
        end
      end

    end
  end
end