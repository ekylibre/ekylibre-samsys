module Backend
  module Visualizations
    class RideSetsVisualizationsController < Backend::VisualizationsController
      respond_to :json

      def show
        colors = ['#b2b2ff', '#7fbf7f', '#ffff66', '#ff7f7f', '#ff4c4c', '#ffb732', '#b266b2']
        ride_set = RideSet.find(params[:ride_set_id])
        ride_set_map = RideSetMap.new(ride_set, view_context)

        config = view_context.configure_visualization do |v|
          options = {fill_opacity: 0.2, fill_color: "#3171A9", color: '#FFFFFF', weight: 3}
          ride_set_map.parcels_near_rides.each do |parcel|
            v.serie parcel[:name], [parcel]
            v.simple parcel[:name], parcel[:name], options
          end
        
          ride_set_map.rides.each do |ride|
            v.serie ride.name, ride.crumbs
            v.paths :ride, ride.name, colors: ride.colors
          end
        end

        respond_with config
      end
    end
  end
end