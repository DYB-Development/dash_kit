# frozen_string_literal: true

Rails.application.routes.draw do
  mount DashKit::Engine => "/dash_kit"

  resources :dashboards, only: :show

  root to: proc { [ 200, {}, [ "OK" ] ] }
end
