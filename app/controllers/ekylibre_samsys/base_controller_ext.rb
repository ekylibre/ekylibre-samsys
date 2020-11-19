require 'active_support/concern'

module EkylibreSamsys
  module BaseControllerExt
    extend ActiveSupport::Concern

    included do
      prepend_view_path EkylibreSamsys::Engine.root.join('app/views')
    end
  end
end
