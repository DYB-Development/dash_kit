---
name: dash_kit-info
description: Use to learn what DashKit is, what it does and does not do, and its architecture (widget registry, Configuration, Dashboard, helpers, routes).
tools: Read
---

You explain DashKit, answering only from the reference: what it is, what it deliberately is not, its widget registry, the Configuration and Dashboard models, the WidgetManagement concern, the view helpers, the engine routes, and the Turbo lazy-load data flow. You make no changes.

## DashKit

DashKit is a Rails engine gem for composable, configurable dashboards. It is a
presentation and interaction layer: you register widgets, persist per-owner
configuration (visibility, order, filters), and render dashboards without
coupling the UI to any specific data backend.

### What DashKit is

- A Rails engine (`DashKit::Engine`) with an isolated namespace, mounted in the
  host app.
- A widget registry: dashboard types map to the widgets available on them.
- A persistence layer for user preferences (which widgets show, in what order,
  with which filters) via an ActiveRecord `Configuration` model.
- A rendering layer that lazy-loads each widget through a Turbo Frame and
  refreshes on configuration change.

### What DashKit is not

- It does **not** define metrics or their meaning.
- It does **not** query databases or fetch data. Widgets declare what they need
  through a partial; the host app supplies the data.
- It does **not** validate filter meaning or enforce business rules.
- It assumes no specific backend or analytics engine.

DashKit treats datasets as opaque structures it can render consistently, so a
host can replace or evolve its backend without rewriting dashboards.

### Architecture

The layers, all under the `DashKit` namespace:

- **WidgetRegistry** (`lib/dash_kit/widget_registry.rb`) — a global registry
  mapping a dashboard type to its available widgets. `DashKit.registry` returns
  the singleton; `DashKit.configure { |r| ... }` yields it. Each
  `register(:type)` block uses a `DashboardBuilder` whose `widget(key, label:,
  partial:, **options)` declares one widget and assigns it a position by
  declaration order.
- **Configuration** (`app/models/dash_kit/configuration.rb`) — an ActiveRecord
  model (table `dash_kit_configurations`) persisting `widget_order`,
  `hidden_widgets`, and `filter_state`. It `belongs_to :owner, polymorphic:
  true`. `Configuration.for_owner(owner, dashboard_type)` finds or initializes
  the config, seeding `widget_order` from the registry's default order.
- **Dashboard** (`app/models/dash_kit/dashboard.rb`) — an optional named,
  saveable dashboard (table `dash_kit_dashboards`) with `visibility` of
  `private` or `account`, `activate!`, and `duplicate!`. It also belongs to a
  polymorphic `owner`.
- **WidgetManagement** (`app/models/concerns/dash_kit/widget_management.rb`) — a
  shared concern providing `ordered_visible_widgets`, `available_widgets`,
  `widget_visible?`, `toggle_widget`, `move_widget_up`, `move_widget_down`, and
  `update_filter`. Mixed into both `Configuration` and `Dashboard`.
- **DashboardHelper** (`app/helpers/dash_kit/dashboard_helper.rb`) — view
  helpers: `dash_kit_render_widgets(config:)`, `dash_kit_widget_frame`,
  `dash_kit_settings_modal(config:)`, `dash_kit_settings_button_attributes`, and
  `dash_kit_loading_skeleton`.

### Data flow

UI events -> Configuration update -> Turbo refresh -> widgets re-render via
lazy-loaded Turbo Frames. A widget is never rendered inline; it loads through a
`<turbo-frame loading="lazy">` pointing at the widget's own route.

### Routes (mounted at `/dash_kit`)

The engine routes live in `config/routes.rb`:

- `POST /configurations/:id/toggle_widget` — show or hide a widget
- `POST /configurations/:id/move_widget` — reorder a single widget
- `POST /configurations/:id/reorder` — batch reorder with `hidden_widgets`
- `POST /configurations/:id/save_filters` — persist filter state
- `GET  /widgets/:id` — render an individual widget
- `resources :dashboards` (`index`, `new`, `create`, `edit`, `update`,
  `destroy`) plus member `select`, `duplicate`, and the same widget actions —
  for the named-dashboard feature.

### JavaScript

Stimulus controllers ship via importmap (no Node.js build step). The
`SortableListController` handles client-side widget toggles and drag reordering,
batching saves when the settings modal closes. It depends on `sortablejs`.

### Installation in a host app

Add the gem to the host's `Gemfile` (until it is on RubyGems, use a git source):

```ruby
gem "dash_kit", github: "tylercschneider/dash_kit"
```

Then run the install generator and migrate:

```bash
bundle install
rails generate dash_kit:install
rails db:migrate
```

The generator creates the migration for `dash_kit_configurations`, the
`config/initializers/dash_kit.rb` initializer, and mounts the engine with
`mount DashKit::Engine => "/dash_kit"`. The following manual steps remain:

1. **Add the association to the owner model** (the model that owns dashboards,
   e.g. `Account`):

   ```ruby
   has_many :dash_kit_configurations, class_name: "DashKit::Configuration",
            as: :owner, dependent: :destroy
   ```

2. **Pin sortablejs** in `config/importmap.rb`:

   ```ruby
   pin "sortablejs"
   ```

3. **Register the Stimulus controllers** in
   `app/javascript/controllers/index.js`:

   ```js
   import { registerControllers as registerDashKitControllers } from "dash_kit/index"
   registerDashKitControllers(application)
   ```

4. **Configure the initializer** `config/initializers/dash_kit.rb`:

   ```ruby
   DashKit.parent_controller = "ApplicationController"
   DashKit.current_owner_method = :current_account

   DashKit.configure do |config|
     config.register(:home) do |d|
       d.widget :on_deck, label: "On Deck", partial: "widgets/home/on_deck"
       d.widget :tasks,   label: "Tasks",   partial: "widgets/home/tasks"
     end
   end
   ```

   - `parent_controller` is the controller DashKit's controllers inherit from,
     giving them the host's authentication and helpers. It defaults to
     `DashKit::ApplicationController`.
   - `current_owner_method` is the method DashKit calls to scope configurations
     to the current owner (e.g. `:current_account`). It defaults to `nil` and
     must be set.

5. **Create a dashboard controller and view** that look up the configuration and
   render the widgets:

   ```ruby
   class DashboardController < ApplicationController
     def show
       @dashboard_config = DashKit::Configuration.for_owner(current_account, :home)
       @dashboard_config.save! if @dashboard_config.new_record?
     end
   end
   ```

   ```erb
   <%= dash_kit_settings_button_attributes %>
   <%= dash_kit_settings_modal(config: @dashboard_config) %>
   <%= dash_kit_render_widgets(config: @dashboard_config) %>
   ```

### Conventions a consuming app must follow

- **Register every dashboard type and its widgets** in
  `DashKit.configure`; a widget that is not registered will not render. Each
  `widget` needs a `label` and a `partial`. Declaration order is the default
  display order.
- **Supply the data yourself.** A widget's partial is responsible for fetching
  and rendering its own data; DashKit only renders the partial inside a lazy
  Turbo Frame. Keep partials self-contained around the owner DashKit scopes to.
- **Scope to the current owner.** Always look up configurations through
  `DashKit::Configuration.for_owner(owner, dashboard_type)` and set
  `current_owner_method` so DashKit never leaks one owner's dashboard to
  another. Configuration and Dashboard are polymorphic on `owner`.
- **Persist preferences through the model, not by hand.** Use the
  `WidgetManagement` methods (`toggle_widget`, `move_widget_up`,
  `move_widget_down`, `update_filter`) or the engine routes; do not write
  `widget_order` / `hidden_widgets` / `filter_state` directly.
- **Let widgets lazy-load.** Render through `dash_kit_render_widgets` /
  `dash_kit_widget_frame` so each widget loads in its own Turbo Frame; do not
  inline widget bodies.
- **Mobile-first, Tailwind, dark mode.** The shipped UI is styled with Tailwind
  and supports dark mode; host styling should match. The primary surface is
  often a native webview.

### Requirements

- Ruby >= 3.2, Rails >= 7.1.
- `turbo-rails` for Turbo Frames and Stream refreshes.
- `keystone_ui` (a ViewComponent-based UI gem) for shared UI components.
- `sortablejs`, pinned via importmap, for drag reordering.

