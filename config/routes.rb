require "sidekiq/web"

Rails.application.routes.draw do
  root to: "home#index"

  devise_for :users

  get "dashboard", to: "dashboard#index", as: :dashboard

  resources :pools, only: [:index, :show] do
    member do
      post :join
      delete :leave
    end
    resources :tips, only: [:index, :create, :update]
    resources :special_bets, only: [:index, :create, :update]
  end

  resources :notifications, only: [:index, :update]
  resource :profile, only: [:show, :edit, :update]

  namespace :admin do
    resources :pools do
      member do
        post :recalculate
        patch :transition
      end
      resources :participants, only: [:index, :update, :destroy]
      resources :matches, only: [:index, :edit, :update]
      resources :webhook_endpoints do
        member { post :test }
      end
      resource :invite, only: [:show, :update]
      resource :sync_schedule, only: [:show, :edit, :update] do
        member { post :force_run }
      end
      resources :sync_logs, only: [:index, :show]
    end
    resources :teams, only: [:new, :create] do
      collection { get :search }
    end
    resources :matches, only: [:new, :create, :edit, :update]
  end

  namespace :super_admin do
    resources :users do
      member do
        post :impersonate
        patch :ban
      end
    end
    resources :pools
    resources :teams
    resources :tournaments do
      member do
        post :sync
        post :seed_from_api
      end
      resources :teams, only: [:index, :new, :create, :destroy], controller: "tournament_teams"
      resources :matches, controller: "tournament_matches"
      resources :stages
      resource :sync_schedule, only: [:show, :edit, :update] do
        member { post :force_run }
      end
      resources :sync_logs, only: [:index, :show]
    end
    resources :matches, only: [:index, :show, :edit, :update]
    resources :api_providers do
      member { post :test_connection }
    end
    resources :webhook_endpoints do
      resources :webhook_deliveries, only: [:index, :show]
      member { post :test }
    end
    resource :settings, only: [:show, :update]

    authenticate :user, ->(u) { u.role_super_admin? } do
      mount Blazer::Engine, at: "blazer"
      mount Sidekiq::Web, at: "sidekiq"
    end
  end

  get "up", to: "rails/health#show", as: :rails_health_check
end
