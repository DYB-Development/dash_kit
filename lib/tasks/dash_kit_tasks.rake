# frozen_string_literal: true

namespace :dash_kit do
  desc "Backfill a Dashboard for each legacy Configuration"
  task backfill_dashboards: :environment do
    DashKit::ConfigurationBackfill.run
    puts "DashKit backfilled Dashboards from Configurations"
  end
end
