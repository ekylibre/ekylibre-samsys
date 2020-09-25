module EkylibreSamsys
  class Engine < ::Rails::Engine
 
  	initializer 'planning.assets.precompile' do |app|
      app.config.assets.precompile += %w( integrations/samsys.png )
    end

    initializer :i18n do |app|
      app.config.i18n.load_path += Dir[EkylibreSamsys::Engine.root.join('config', 'locales', '**', '*.yml')]
    end

    initializer :extend_navigation do |_app|
      EkylibreSamsys::ExtNavigation.add_navigation_xml_to_existing_tree
    end

    initializer :extend_controllers do |app|
      app.config.paths['app/views'].unshift EkylibreSamsys::Engine.root.join('app/views').to_s
      ::Backend::ProductsController.send(:include, ::EkylibreSamsys::BaseControllerExt)
      ::Backend::ProductsController.class_eval do
        prepend_view_path EkylibreSamsys::Engine.root.join('app/views').to_s
        before_action :prepare_views

        def prepare_views
          prepend_view_path EkylibreSamsys::Engine.root.join('app/views').to_s
        end
      end
    end

  end
end
