module EkylibreSamsys
  module ProductsControllerExt
    extend ActiveSupport::Concern

    included do
      list(:links, model: :product_link, conditions: { product_id: 'params[:id]'.c }) do |t|
        t.column :nature
        t.column :linked_id, url: { controller: 'backend/equipments', id: 'RECORD.linked_id'.c }, label_method: :linked_name
      end
    end
  end
end