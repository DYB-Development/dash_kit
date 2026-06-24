module DashKit
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :null_session
    helper KeystoneUi::Engine.helpers
  end
end
