DashKit::Engine.routes.draw do
  resources :widgets, only: [ :show ]
  resources :widget_definitions, only: [ :show ]

  resources :dashboards, only: [ :index, :new, :create, :edit, :update, :destroy ] do
    member do
      post :select
      post :duplicate
      post :save_filters
      get "layout", to: "dashboards#layout", as: :layout
      post "blocks", to: "dashboards#add_block", as: :blocks
      patch "blocks", to: "dashboards#place_blocks"
      delete "blocks/:block_id", to: "dashboards#remove_block", as: :block
      post :create_definition
      post :update_definition
      post :destroy_definition
    end
  end
end
