class RideMap
  attr_reader :resource, :view

  def initialize(ride, view)
    @resource = ride
    @view = view
  end

  def crumbs
    ride_crumbs = resource.crumbs.where(nature: "point").order(:read_at).map do |crumb|
      if crumb.geolocation
        {
          nature: crumb.nature,
          name: crumb.nature,
          shape: Charta.new_geometry(crumb.geolocation),
          read_at: crumb.read_at,
          trajet: resource.number
        }
      end
    end
  end

  def pause_crumbs
    pause_crumbs = resource.crumbs.where(nature: "pause").map do |crumb|
      if crumb.geolocation
        pause_popup = view.render(partial: 'popup', locals: { crumb: crumb })
        header_content = view.content_tag(:span, :pause.tl, class: 'sensor-name')
        {
          name: crumb.nature,
          shape: Charta.new_geometry(crumb.geolocation),
          popup: { header: header_content, content: pause_popup }
        }
      end
    end
  end

  def start_end_crumbs
    start_end_crumb = resource.crumbs.where(nature: ["hard_start", "hard_stop"]).order(:read_at).map do |crumb|
      if crumb.geolocation
        {
          nature: crumb.nature,
          name: crumb.nature.tl,
          shape: Charta.new_geometry(crumb.geolocation),
        }
      end
    end
  end

  def parcels_near_ride
    @parcels_near_ride ||= near_parcels.map do |parcel|
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