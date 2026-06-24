# frozen_string_literal: true

require "test_helper"
require "rake"

class DashKit::BackfillDashboardsTaskTest < ActiveSupport::TestCase
  setup do
    @account = Account.create!(name: "Test")
    Rake.application = Rake::Application.new
    Rake::Task.define_task(:environment)
    load File.expand_path("../../lib/tasks/dash_kit_tasks.rake", __dir__)
  end

  test "dash_kit:backfill_dashboards backfills Dashboards from Configurations" do
    DashKit::ConfigurationBackfill::LegacyConfiguration.create!(
      owner_type: @account.class.name, owner_id: @account.id, dashboard_type: "home"
    )

    Rake::Task["dash_kit:backfill_dashboards"].invoke

    assert DashKit::Dashboard.for_owner(@account).exists?(dashboard_type: "home")
  end
end
