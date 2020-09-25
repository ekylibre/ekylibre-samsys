require "ekylibre-samsys/engine"
require "ekylibre-samsys/ext_navigation"


module EkylibreSamsys
  def self.root
    Pathname.new(File.dirname __dir__)
  end
end
