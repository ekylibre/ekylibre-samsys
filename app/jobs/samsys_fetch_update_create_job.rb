class SamsysFetchUpdateCreateJob < ActiveJob::Base
  queue_as :default

  def perform

    # transcode Samsys machine type in Ekylibre machine nature
    transcode_machine_type = {
                            "Micro tracteur" => :tractor, "Tracteur agricole" => :tractor,
                            "Tracteur de pente" => :tractor, "Tracteur enjambeur" => :tractor,
                            "Tracteur forestier" => :tractor, "Tracteur fruitier" => :tractor,
                            "Tracteur vigneron" => :tractor, "Unimog" => :tractor
                          }.freeze

    #TODO call get_token method here to avoid multiple call of get_token during one session

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

          # Find or create an equipment corresponding to the sensor

          if counter[:association].any? && counter[:association][:machine].any?
            counter[:association][:machine].each do |machine|
              # Find or create an equipement corresponding to the machine
              # machine[:id]
              # machine[:name]
              # machine[:brand]
              # machine[:machine_type]
              puts machine.inspect.yellow



              # Link the sensor to the machine
              # counter[:association][:id]
              # counter[:association][:start_date]
              # counter[:association][:end_date]


            end
          end

        end
      end
    end


  end
end
