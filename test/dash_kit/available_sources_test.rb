# frozen_string_literal: true

require "test_helper"

class DashKit::AvailableSourcesTest < ActiveSupport::TestCase
  teardown do
    DashKit.available_sources_for = DashKit::NO_SOURCES
  end

  test "available_sources is empty by default" do
    assert_equal [], DashKit.available_sources("viewer-1")
  end
end
