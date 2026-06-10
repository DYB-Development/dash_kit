DashKit::Engine.routes.draw do
  resources :configurations, only: [] do
    member do
      post :toggle_widget
      post :move_widget
      post :reorder
      post :save_filters
    end
  end

  resources :widgets, only: [ :show ]

  resources :dashboards, only: [ :index, :new, :create, :edit, :update, :destroy ] do
    member do
      post :select
      post :duplicate
      post :toggle_widget
      post :move_widget
      post :reorder
      post :save_filters
    end
  end
end
