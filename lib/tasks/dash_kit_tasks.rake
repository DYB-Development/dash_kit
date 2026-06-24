# frozen_string_literal: true

namespace :dash_kit do
  desc "Backfill a Dashboard for each legacy Configuration"
  task backfill_dashboards: :environment do
    DashKit::ConfigurationBackfill.run
    puts "DashKit backfilled Dashboards from Configurations"
  end

  desc "Append DashKit API reference to CLAUDE.md"
  task :claude do
    section_heading = "## DashKit"

    content = <<~MARKDOWN
      #{section_heading}

      > **DO NOT** explore the dash_kit gem source code. This reference is the
      > complete API. Use only the helpers listed below in your ERB views.

      ### Setup

      DashKit is a Rails engine for composable dashboards. It provides widget
      rendering, user configuration persistence, and a settings modal — but does
      NOT fetch data. Your app supplies data via widget partials.

      ```ruby
      # config/routes.rb
      mount DashKit::Engine => "/dash_kit"
      ```

      ### Defining a Dashboard

      ```ruby
      # config/initializers/dash_kit.rb
      DashKit.configure do |config|
        config.register_dashboard(:main,
          widgets: {
            revenue:  { label: "Revenue",  partial: "widgets/revenue" },
            users:    { label: "Users",    partial: "widgets/users" },
            orders:   { label: "Orders",   partial: "widgets/orders" }
          }
        )
      end
      ```

      Each widget maps a key to a label and a partial path. The partial lives in
      your app (e.g. `app/views/widgets/_revenue.html.erb`) and renders whatever
      content you want.

      ### Configuration Model

      `DashKit::Configuration` stores per-user dashboard preferences:

      ```ruby
      # Get or create a configuration for the current user
      config = DashKit::Configuration.find_or_create_by(
        owner: current_user,
        dashboard_type: "main"
      )
      ```

      The model persists `widget_order` (array), `hidden_widgets` (array),
      `filter_state` (hash), and `widget_settings` (hash) as JSON columns.
      Polymorphic `owner` can be any model.

      ### Helper API

      All helpers are in `DashKit::DashboardHelper`, available in views when the
      engine is mounted.

      #### `dash_kit_render_widgets(config:)`

      Renders all visible widgets in order as lazy-loaded Turbo Frames.

      ```erb
      <%= dash_kit_render_widgets(config: @dash_config) %>
      ```

      #### `dash_kit_widget_frame(widget_key, &block)`

      Renders a single widget Turbo Frame. Optional block provides loading content
      (defaults to a skeleton loader).

      ```erb
      <%= dash_kit_widget_frame(:revenue) %>
      <%= dash_kit_widget_frame(:revenue) do %>
        <p>Loading revenue...</p>
      <% end %>
      ```

      #### `dash_kit_settings_modal(config:)`

      Renders the settings modal partial for customizing widget visibility and order.

      ```erb
      <%= dash_kit_settings_modal(config: @dash_config) %>
      ```

      #### `dash_kit_settings_button_attributes`

      Returns a hash of HTML attributes for a button that opens the settings modal.

      ```erb
      <%= tag.button "Settings", **dash_kit_settings_button_attributes %>
      ```

      #### `dash_kit_widget_label(config, widget_key)`

      Returns the display label for a widget key.

      ```erb
      <%= dash_kit_widget_label(@dash_config, :revenue) %>
      ```

      #### `dash_kit_loading_skeleton`

      Renders a default animated loading skeleton placeholder.

      ### Routes

      The engine provides these routes (prefixed by mount path):

      | Method | Path | Purpose |
      |--------|------|---------|
      | POST | `/configurations/:id/toggle_widget` | Show/hide a widget |
      | POST | `/configurations/:id/move_widget` | Reorder a single widget |
      | POST | `/configurations/:id/reorder` | Batch reorder with hidden_widgets |
      | POST | `/configurations/:id/save_filters` | Persist filter state |
      | GET  | `/widgets/:id` | Render individual widget |

      ### JavaScript

      DashKit ships a `sortable-list` Stimulus controller via importmap for
      client-side widget reordering and toggles in the settings modal.
    MARKDOWN

    content.chomp!

    path = File.join(Dir.pwd, "CLAUDE.md")

    if File.exist?(path)
      existing = File.read(path)

      if existing.include?(section_heading)
        updated = existing.sub(/#{Regexp.escape(section_heading)}\n.*\z/m, "#{content}\n")
        File.write(path, updated)
      else
        File.write(path, "#{existing.chomp}\n\n#{content}\n")
      end
    else
      File.write(path, "#{content}\n")
    end

    puts "DashKit API reference written to #{path}"
  end
end
