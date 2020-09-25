$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "ekylibre-samsys/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ekylibre-samsys"
  s.version     = EkylibreSamsys::VERSION
  s.authors     = ["RG24"]
  s.email       = ["groche@ekylibre.com"]
  s.summary     = "Samsys plugin for Ekylibre"
  s.description = "Samsys plugin for Ekylibre"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc", "Capfile"]
  s.require_path = ['lib']
  s.test_files = Dir["test/**/*"]

  s.add_dependency 'capistrano-git-with-submodules', '~> 2.0'
  s.add_dependency 'capistrano-nvm'
  s.add_dependency 'capistrano-rails'
  s.add_dependency "rails", "~> 4.2.11.1"

  s.add_development_dependency "pg"
  s.add_development_dependency "rubocop"
  s.add_development_dependency "rubocop-rails"
end
