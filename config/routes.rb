require "sidekiq/web"

Rails.application.routes.draw do
  root to: "home#index"

  devise_for :users

  get "dashboard", to: "dashboard#index", as: :dashboard

  resources :my_pools, only: [ :new, :create, :edit, :update, :destroy ], path: "meus-boloes"
  resources :matches, only: [ :show ]
  get  "join/:invite_code", to: "pools#join_by_code", as: :join_pool_by_code
  post "join/:invite_code", to: "pools#accept_invite", as: :accept_pool_invite

  resources :pools, only: [ :index, :show ] do
    member do
      post :join
      delete :leave
      get :match_panel
      post :recalculate_ranking
    end
    resources :tips, only: [ :index, :create, :update ]
  end

  resources :notifications, only: [ :index, :update ]
  resource :profile, only: [ :show, :edit, :update ]

  namespace :admin do
    resources :pools do
      member do
        post :recalculate
        patch :transition
      end
      resources :participants, only: [ :index, :update, :destroy ]
      resources :matches, only: [ :index, :edit, :update ] do
        collection { post :sync_from_api }
      end
      resources :lineup, only: [ :index, :create, :destroy ] do
        collection do
          post :import_tournament
          post :import_api
        end
      end
      resources :webhook_endpoints do
        member { post :test }
      end
      resource :invite, only: [ :show, :update ]
      resource :sync_schedule, only: [ :show, :edit, :update ] do
        member { post :force_run }
      end
      resources :sync_logs, only: [ :index, :show ]
    end
    resources :teams, only: [ :new, :create ] do
      collection { get :search }
    end
    resources :matches, only: [ :index, :show, :new, :create, :edit, :update ]
  end

  namespace :super_admin do
    resources :users do
      member do
        post :impersonate
        patch :ban
      end
    end
    resources :pools
    resources :teams do
      collection do
        post :import_from_tsdb
        delete :batch_destroy
      end
    end
    resources :tournaments do
      collection { post :import_from_tsdb }
      member do
        post :sync
        post :seed_from_api
        post :import_teams
        post :import_matches
      end
      resources :teams, only: [ :index, :new, :create, :destroy ], controller: "tournament_teams"
      resources :matches, controller: "tournament_matches"
      resources :stages
      resource :sync_schedule, only: [ :show, :edit, :update ] do
        member { post :force_run }
      end
      resources :sync_logs, only: [ :index, :show ]
    end
    resources :matches, only: [ :index, :show, :edit, :update, :destroy ] do
      collection do
        post :import_from_tsdb
        delete :batch_destroy
      end
    end
    resources :api_providers do
      member { post :test_connection }
    end
    resources :webhook_endpoints do
      resources :webhook_deliveries, only: [ :index, :show ]
      member { post :test }
    end
    resource :settings, only: [ :show, :update ]

    authenticate :user, ->(u) { u.role_super_admin? } do
      mount Blazer::Engine,           at: "blazer"
      mount Sidekiq::Web,             at: "sidekiq"
      mount RailsRealtimeErd::Engine, at: "erd"
    end
  end

  get "up", to: "rails/health#show", as: :rails_health_check
end
