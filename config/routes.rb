Rails.application.routes.draw do

  concern :list do
    get :list, on: :collection
  end

  namespace :backend do
    resources :rides, concerns: %i[list], only: %i[index show destroy]
  end

  namespace :backend do
    resources :ride_sets, concerns: %i[list], only: %i[index show destroy] do
      member do
        get :list_rides
      end
    end

    namespace :visualizations do
      resource :ride_sets_visualizations, only: :show
      resource :rides_visualizations, only: :show
    end
    get :samsys_synchro, to: 'ride_sets#synchronize'
    get :samsys_delete_selected_ride_sets, to: 'ride_sets#delete_selected_ride_sets'
  end

end
