# # Rails.application.routes.draw do
# #   # Devise mappings must be created first
# #   devise_for :users, controllers: {
# #     sessions: "users/sessions"
# #   }

# #   namespace :admin do
# #     get "dashboard", to: "dashboard#index"
# #   end

# #   # Authenticated users => their root (must come BEFORE the unauthenticated root)
# #   authenticated :user do
# #     root to: "youtube_channels#index", as: :authenticated_root
# #   end

# #   # For unauthenticated users, tell Devise explicitly which mapping to use.
# #   # Wrapping the root in devise_scope ensures Devise sets up the mapping for :user,
# #   # which prevents the "Could not find devise mapping for path '/'" error.
# #   devise_scope :user do
# #     root to: "users/sessions#new"
# #   end

# #   resources :youtube_channels
# #   resources :users, only: %i[index show create update destroy]
# # end
# # config/routes.rb# config/routes.rb
# Rails.application.routes.draw do
#   devise_for :users, controllers: {
#     sessions: "users/sessions"
#   }

#   # Namespaced dashboards / management
#   namespace :admin do
#     get "dashboard", to: "dashboard#index", as: :dashboard
#     resources :users, only: %i[index show edit update destroy]
#     resources :youtube_channels do
#       member { post :sync }
#     end
#     resources :streams
#   end

#   namespace :stream_operator do
#     get "dashboard", to: "dashboard#index", as: :dashboard
#     resources :youtube_channels, only: %i[index show new create edit update destroy]
#     resources :streams, only: %i[index show new create edit update destroy]
#   end

#   namespace :production_operator do
#     get "dashboard", to: "dashboard#index", as: :dashboard
#     resources :youtube_channels, only: %i[index show]
#     resources :streams, only: %i[index show edit update]
#   end

#   # Authenticated users => main app root (fallback)
#   authenticated :user do
#     root to: "youtube_channels#index", as: :authenticated_root
#   end

#   # Public/devise root
#   devise_scope :user do
#     root to: "users/sessions#new"
#   end

#   # Top-level controllers (public or fallback)
#   resources :youtube_channels, only: %i[index show]
#   resources :streams, only: %i[index show]
#   resources :users, only: %i[index show create update destroy]
# end
Rails.application.routes.draw do
  # Devise mappings must be created first
  devise_for :users, controllers: {
    sessions: "users/sessions"
  }

  namespace :admin do
    get "dashboard", to: "dashboard#index", as: :dashboard
    resources :users, only: %i[index show edit update destroy]
    resources :youtube_channels do
      member { post :sync }
    end
    resources :streams
  end

  namespace :stream_operator do
    get "dashboard", to: "dashboard#index", as: :dashboard
    resources :youtube_channels, only: %i[index show new create edit update destroy]
    resources :streams, only: %i[index show new create edit update destroy]
  end

  namespace :production_operator do
    get "dashboard", to: "dashboard#index", as: :dashboard
    resources :youtube_channels, only: %i[index show]
    resources :streams, only: %i[index show edit update]
  end

  authenticated :user do
    root to: "youtube_channels#index", as: :authenticated_root
  end

  devise_scope :user do
    root to: "users/sessions#new"
  end

  resources :youtube_channels, only: %i[index show]
  resources :streams, only: %i[index show]
  resources :users, only: %i[index show create update destroy]
end
