Rails.application.routes.draw do

  mount SabisuRails::Engine => "/sabisu_rails"
  devise_for :users

  # Api definition
  namespace :api, defaults: { format: :json } do
    # We are going to list our resources here

    namespace :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      # We are going to list our resources here
      resources :users, :only => [:index, :show, :create, :update, :destroy]
      resources :sessions, :only => [:create, :destroy]
      
      # Amadeus client routes
      post 'amadeus/raw_query' => 'amadeus_client#raw_query' 
      post 'amadeus/search_flight' => 'amadeus_client#search_flight' 
    end
  end

end
