Rails.application.routes.draw do
  # auth
  post "/login", to: "sessions#create"

  # users
  resources :users, only: [:create, :index, :show, :update, :destroy]

end
