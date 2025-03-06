Rails.application.routes.draw do
  root "forecasts#new"
  resources :forecasts, only: [:new, :create]
  get "up" => "rails/health#show", as: :rails_health_check
end
