# frozen_string_literal: true

module DashKit
  module Reference
    GUIDE_PATH = File.expand_path("reference/guide.md", __dir__)

    def self.content
      File.read(GUIDE_PATH)
    end
  end
end
