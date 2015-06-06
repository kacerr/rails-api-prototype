Rails.application.routes.draw do

  devise_for :users
  # Api definition
  namespace :api, defaults: { format: :json } do
    # We are going to list our resources here

    scope module: :v1,
              constraints: ApiConstraints.new(version: 1, default: true) do
      # We are going to list our resources here
    end
  end

end
