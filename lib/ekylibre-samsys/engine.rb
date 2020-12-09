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

    initializer :ekylibre_ekyviti_extend_controllers do |_app|
      ::Backend::ProductsController.include EkylibreSamsys::ProductsControllerExt
    end

    config.after_initialize do |app|
      ::Backend::ProductsController.prepend_view_path EkylibreSamsys::Engine.root.join('app/views')
    end
  end
end
