# frozen_string_literal: true

require "test_helper"
require "the_local"
require "dash_kit/the_local"

class DashKit::TheLocalDriftTest < Minitest::Test
  def test_committed_locals_match_rendered_markdown
    agents = registered_agents

    refute_empty agents, "expected dash_kit to register at least one local"

    agents.each do |agent|
      committed = File.read(agent.source_path)

      assert_equal agent.to_markdown, committed,
        "#{agent.source_path} has drifted from agent.to_markdown; run `rake the_local:build`"
    end
  end

  private

  def registered_agents
    TheLocal.registry.agents.select { |agent| agent.gem_name == "dash_kit" }
  end
end
