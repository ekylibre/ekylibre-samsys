class RideSetMap
  COLORS = %w[#b2b2ff #7fbf7f #ffff66 #ff7f7f #ff4c4c #ffb732 #b266b2].freeze
  attr_reader :resource, :view

  def initialize(ride_set, view)
    @resource = RideSet.find(ride_set.id)
    @view = view
  end

  def rides
    resource.rides.map.with_index do |ride, index|
      ride_crumbs = ride.path_map.map do |path_map|
        { shape: Charta.new_geometry(path_map),
        ride: ride.number }
      end
      OpenStruct.new({ name: ride.number, crumbs: ride_crumbs, colors: [COLORS[index % COLORS.length]] })
    end
  end


  def parcels_near_rides
    binding.pry
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
      crumbs_line = resource.crumbs_line
      LandParcel.at(resource.started_at).shape_intersecting(crumbs_line)
      #LandParcel.at(resource.started_at).initial_shape_near(crumbs_line, 100)

      # crumbs_line = resource.crumbs_line
      # line_buffer_working_zone = crumbs_line.buffer(5)
      # LandParcel.at(resource.started_at).initial_shape_near(line_buffer_working_zone, 100)

    end
end