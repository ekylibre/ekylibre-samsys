class RideSetMap
  COLORS = %w[#b2b2ff #7fbf7f #ffff66 #ff7f7f #ff4c4c #ffb732 #b266b2 #4a94b9 #7fbf7f #ffff66 #94de94 #6f256f #6fb900 #ff4c4c #ffb732 #b9944a].freeze
  attr_reader :resource, :view

  def initialize(ride_set, view)
    @resource = RideSet.find(ride_set.id)
    @view = view
  end

  def rides
    resource.rides.map.with_index do |ride, index|
      shape = [{ shape: Charta.new_geometry(ride.shape), ride: ride.number }]    
      OpenStruct.new({ name: ride.number, linestring: shape, colors: [COLORS[index % COLORS.length]] })
    end
  end

  def parcels_near_rides
    near_parcels.map do |parcel|
      popup_parcel = view.render(partial: 'backend/rides/popup_land_parcel', locals: { parcel: parcel })
      header_content = view.content_tag(:span, parcel.name, class: 'sensor-name')
      { name: parcel.name,
        shape: parcel.initial_shape,
        popup: { header: header_content, content: popup_parcel } }
    end
  end

  private

    def near_parcels
      line = resource.shape
      LandParcel.at(resource.started_at).shape_intersecting(line)
    end
end