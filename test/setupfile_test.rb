# frozen_string_literal: true

require "test_helper"
require "dev_onboarder/requirements"

class SetupfileTest < ActiveSupport::TestCase
  ROOT = File.expand_path("..", __dir__)

  test "the setup file requires the test suite to pass" do
    assert_equal "bundle exec rake test", check_of(:test_suite)
  end

  test "the setup file requires the Symphony rules and scribes to be installed for Claude Code" do
    assert_includes requirements.map(&:key), :symphony
  end

  test "the setup file installs the Claude subagents the bundle provides" do
    assert_equal "bundle exec the_local install", check_of(:locals)
  end

  test "git ignores a developer\x27s setup record" do
    assert system("git", "check-ignore", "--quiet", ".dev_onboarder.json", chdir: ROOT)
  end

  private

  def check_of(key)
    requirements.find { |requirement| requirement.key == key }&.check
  end

  def requirements
    DevOnboarder::Requirements.load(File.join(ROOT, "Setupfile"))
  end
end
