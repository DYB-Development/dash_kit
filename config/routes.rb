DashKit::Engine.routes.draw do
  resources :widgets, only: [ :show ]
  resources :widget_definitions, only: [ :show ]

  resources :dashboards, only: [ :index, :new, :create, :edit, :update, :destroy ] do
    member do
      post :select
      post :duplicate
      post :save_filters
      patch "blocks", to: "dashboards#place_blocks", as: :blocks
      post :create_definition
      post :update_definition
      post :destroy_definition
    end
  end
end
