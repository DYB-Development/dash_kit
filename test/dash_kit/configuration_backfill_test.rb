# frozen_string_literal: true

require "test_helper"

class DashKit::ConfigurationBackfillTest < ActiveSupport::TestCase
  setup do
    @account = Account.create!(name: "Test")
  end

  test "creates a Dashboard for each Configuration" do
    DashKit::Configuration.create!(owner: @account, dashboard_type: "home")

    DashKit::ConfigurationBackfill.run

    assert DashKit::Dashboard.for_owner(@account).exists?(dashboard_type: "home")
  end
end
