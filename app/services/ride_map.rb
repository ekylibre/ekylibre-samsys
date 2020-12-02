class RideMap
  attr_reader :resource, :view

  def initialize(ride, view)
    @resource = ride
    @view = view
  end

  def crumbs
    resource.crumbs.where(nature: "point").order(:read_at).map do |crumb|
      {
        shape: Charta.new_geometry(crumb.geolocation),
        ride: resource.number
      }
    end
  end

  def pause_crumbs
    @pause_crumbs ||= resource.crumbs.where(nature: "pause").map do |crumb|
      pause_popup = view.render(partial: 'popup', locals: { crumb: crumb })
      header_content = view.content_tag(:span, :pause.tl, class: 'sensor-name')
      {
        shape: Charta.new_geometry(crumb.geolocation),
        popup: { header: header_content, content: pause_popup }
      }
    end
  end

  def start_end_crumbs
    resource.crumbs.where(nature: ["hard_start", "hard_stop"]).order(:read_at).map do |crumb|
      {
        name: crumb.nature.tl,
        shape: Charta.new_geometry(crumb.geolocation)
      }
    end
  end

  def parcels_near_ride
    near_parcels.map do |parcel|
      popup_parcel = view.render(partial: 'backend/rides/popup_land_parcel', locals: { parcel: parcel })
      header_content = view.content_tag(:span, parcel.name, class: 'sensor-name')
      { name: parcel.name,
        shape: parcel.initial_shape,
        popup: { header: header_content, content: popup_parcel }}
    end
  end

  private

    def near_parcels
      crumbs_line = ::Charta.make_line(resource.crumbs.order(:read_at).pluck(:geolocation)).simplify(0.0001)
      LandParcel.availables(at: resource.started_at).initial_shape_near(crumbs_line, 100)
    end
end