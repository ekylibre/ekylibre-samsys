module EkylibreSamsys
  class Engine < ::Rails::Engine
    initializer 'ekylibre_samsys.assets.precompile' do |app|
      app.config.assets.precompile += %w[rides.js integrations/samsys.png]
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
        SamsysFetchUpdateCreateJob.perform_later(stopped_on: Time.now.to_s, started_on: (Time.now - 365.days).to_s)
      end

      Samsys::SamsysIntegration.run every: :day do
        if Integration.find_by(nature: 'samsys').present?
          SamsysFetchUpdateCreateJob.perform_now(stopped_on: Time.now.to_s, started_on: (Time.now - 1.days).to_s)
        end
      end
    end

    initializer :ekylibre_samsys_import_javascript do
      tmp_file = Rails.root.join('tmp', 'plugins', 'javascript-addons', 'plugins.js.coffee')
      tmp_file.open('a') do |f|
        import = '#= require rides'
        f.puts(import) unless tmp_file.open('r').read.include?(import)
      end
    end

    initializer :add_samsys_partials do |_app|
      Ekylibre::View::Addon.add(:extensions_content_top, 'backend/ride_sets/synchro', to: 'backend/ride_sets#index')
    end

  end
end