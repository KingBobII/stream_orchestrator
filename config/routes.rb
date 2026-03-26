Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: "users/sessions"
  }

  namespace :admin do
    get "dashboard", to: "dashboard#index", as: :dashboard

    resources :users, only: %i[index show edit update destroy]

    resources :youtube_channels do
      member do
        post :sync
        get :connect
        post :disconnect
      end

      collection do
        get :oauth_callback
      end
    end

    resources :streams do
      member do
        post :sync_to_youtube
      end

      collection do
        post :sync_pending_to_youtube
      end
    end

    resources :schedule_imports, only: %i[new create show] do
      member do
        get :review
        patch :confirm
      end
    end
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
