class RideSetMap
  COLORS = %w[#b2b2ff #7fbf7f #ffff66 #ff7f7f #ff4c4c #ffb732 #b266b2].freeze
  attr_reader :resource, :view

  def initialize(ride_set, view)
    @resource = RideSet.includes(rides: :crumbs).where.not(crumbs: { nature: 'pause' }).order('crumbs.read_at').find(ride_set.id)
    @view = view
  end

  def rides
    @rides ||= resource.rides.map.with_index do |ride, index|
      popup_lines = view.render(partial: 'popup', locals: { crumb: ride.crumbs.first })
      ride_crumbs = ride.crumbs.map do |crumb|
        { name: crumb.nature,
          shape: Charta.new_geometry(crumb.geolocation),
          read_at: crumb.read_at,
          popup: { header: :ride_geo.tl, content: popup_lines },
          Ride: crumb.ride.number }
      end
      OpenStruct.new({ name: ride.number, crumbs: ride_crumbs, colors: [COLORS[index % COLORS.length]] })
    end
  end

  def parcels_near_rides
    @parcels_near_rides ||= near_parcels.map do |parcel|
      popup_parcel = view.render(partial: 'backend/rides/popup_land_parcel', locals: { parcel: parcel })
      header_content = view.content_tag(:span, parcel.name, class: 'sensor-name')
      { id: parcel.id,
        name: parcel.name,
        shape: parcel.initial_shape,
        popup: { header: header_content, content: popup_parcel },
        net_surface_area: parcel.net_surface_area }
    end
  end

  private

    def near_parcels
      crumbs_line = ::Charta.make_line(resource.crumbs.order(:read_at).pluck(:geolocation)).simplify(0.0001)
      LandParcel.availables(at: resource.started_at).initial_shape_near(crumbs_line, 100)
    end
end