Rails.application.routes.draw do

  # namespace :backend, only: :list_links do
  #   resources :products do
  #     member do
  #       get :list_links
  #     end
  #   end
  # end


  concern :list do
    get :list, on: :collection
  end

  namespace :backend, only: :list_links do
    resources :equipments do
      member do
        get :list_links
      end
    end
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
  end

end
