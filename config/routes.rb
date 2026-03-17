Rails.application.routes.draw do
  # Devise mappings must be created first
  devise_for :users, controllers: {
    sessions: "users/sessions"
  }

  namespace :admin do
    get "dashboard", to: "dashboard#index"
  end

  # Authenticated users => their root (must come BEFORE the unauthenticated root)
  authenticated :user do
    root to: "youtube_channels#index", as: :authenticated_root
  end

  # For unauthenticated users, tell Devise explicitly which mapping to use.
  # Wrapping the root in devise_scope ensures Devise sets up the mapping for :user,
  # which prevents the "Could not find devise mapping for path '/'" error.
  devise_scope :user do
    root to: "users/sessions#new"
  end

  resources :youtube_channels
  resources :users, only: %i[index show create update destroy]
end
