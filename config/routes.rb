Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Root redirect
  root "sessions#new"

  # Authentication
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  # Employee Dashboard
  get "dashboard", to: "dashboards#show", as: :dashboard

  # Employee Leave Requests
  resources :leave_requests, only: [:index, :show, :new, :create] do
    collection do
      get :check_conflicts
    end
  end

  # Manager Portal
  namespace :manager do
    resources :leave_requests, only: [:index, :show] do
      member do
        patch :approve
        patch :reject
      end
    end
    resource :calendar, only: [:show]
  end
end
