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

  # AI Leave Assistant
  get "ai_assistant", to: "ai_assistant#show", as: :ai_assistant
  post "ai_assistant/generate_summary", to: "ai_assistant#generate_summary", as: :generate_summary
  post "ai_assistant/chat", to: "ai_assistant#chat", as: :ai_chat
  delete "ai_assistant/clear_chat", to: "ai_assistant#clear_chat", as: :clear_ai_chat
  patch "notifications/:id/read", to: "ai_assistant#mark_notification_read", as: :mark_notification_read
  patch "notifications/read_all", to: "ai_assistant#mark_all_notifications_read", as: :mark_all_notifications_read

  # Manager Portal
  namespace :manager do
    resources :leave_requests, only: [:index, :show] do
      member do
        patch :approve
        patch :reject
      end
    end
    resource :calendar, only: [:show]
    resource :analytics, only: [:show]
  end
end
