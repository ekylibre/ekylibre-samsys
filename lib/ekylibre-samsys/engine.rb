module EkylibreSamsys
  class Engine < ::Rails::Engine
    initializer 'ekylibre_samsys.assets.precompile' do |app|
      app.config.assets.precompile += %w(integrations/samsys.png)
    end

    initializer :ekylibre_samsys_i18n do |app|
      app.config.i18n.load_path += Dir[EkylibreSamsys::Engine.root.join('config', 'locales', '**', '*.yml')]
    end

    initializer :ekylibre_samsys_extend_navigation do |_app|
      EkylibreSamsys::ExtNavigation.add_navigation_xml_to_existing_tree
    end

    initializer :ekylibre_samsys_restfully_manageable do |app|
      app.config.x.restfully_manageable.view_paths << EkylibreSamsys::Engine.root.join('app', 'views')
    end

    initializer :ekylibre_samsys_integration do
      Samsys::SamsysIntegration.on_check_success do
        SamsysFetchUpdateCreateJob.perform_later
      end

      Samsys::SamsysIntegration.run every: :hour do
        if Integration.find_by(nature: "samsys").present?
          SamsysFetchUpdateCreateJob.perform_now
        end
      end
    end
  end
end
