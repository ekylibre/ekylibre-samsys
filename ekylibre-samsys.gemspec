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
end
