class RideMap
  attr_reader :resource, :view

  def initialize(ride, view)
    @resource = ride
    @view = view
  end

  def linestring
    [{ shape: Charta.new_geometry(resource.shape), ride: resource.number }]
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
      line = resource.ride_set.shape
      LandParcel.at(resource.started_at).shape_intersecting(line)
    end
end