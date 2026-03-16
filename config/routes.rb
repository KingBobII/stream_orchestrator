# config/routes.rb
Rails.application.routes.draw do
  devise_for :users, controllers: { sessions: "users/sessions" }

  # existing routes...
  resources :users, only: [:index, :show, :create, :update, :destroy]
  resources :youtube_channels
  # ... other routes
end
