DashKit::Engine.routes.draw do
  resources :widgets, only: [ :show ]
  resources :widget_definitions, only: [ :show ]

  resources :dashboards, only: [ :index, :new, :create, :edit, :update, :destroy ] do
    member do
      post :select
      post :duplicate
      post :toggle_widget
      post :move_widget
      post :reorder
      post :save_filters
      post :create_definition
    end
  end
end
