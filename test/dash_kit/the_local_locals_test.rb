# frozen_string_literal: true

require "test_helper"
require "the_local/front_matter"

class DashKit::TheLocalLocalsTest < Minitest::Test
  def test_a_host_can_read_the_front_matter_of_every_committed_local
    scopes = committed_locals.map { |file| TheLocal::FrontMatter.new(File.read(file)).scope }

    assert_equal committed_locals.size, scopes.size
  end

  private

  def committed_locals
    @committed_locals ||= Dir.glob(File.expand_path("../../lib/dash_kit/the_local/agents/*.md", __dir__))
  end
end
