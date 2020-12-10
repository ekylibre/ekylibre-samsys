module EkylibreSamsys
  module EquipmentsControllerExt
    extend ActiveSupport::Concern

    included do
      before_action :set_views_path

      def set_views_path
        prepend_view_path EkylibreSamsys::Engine.root.join('app', 'views')
      end

      list(:links, model: :product_link, conditions: { product_id: 'params[:id]'.c }) do |t|
        t.column :nature
        t.column :linked_id, url: { controller: 'backend/equipments', id: 'RECORD.linked_id'.c }, label_method: :linked_name
      end
    end
  end
end
