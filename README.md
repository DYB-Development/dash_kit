# DashKit

## What DashKit Is

DashKit is a Ruby / Rails UI engine for composing, configuring, and rendering dashboards. It provides a presentation and interaction layer that lets teams build reusable dashboards and widgets without tying the UI to any specific backend or data system.

## What DashKit Is Not

DashKit does **not**:

- Define metrics or their meaning.
- Query databases or execute data retrieval logic.
- Validate metric correctness or enforce business rules.
- Assume any specific backend or analytics engine.

DashKit expects an external data provider to supply datasets. It focuses solely on rendering dashboards from those datasets.

## High-Level Architecture

```
UI events → DataProvider → Dataset → Rendering
```

DashKit turns user intent (filters, time ranges, widget configs) into a request for a data provider, receives a dataset, and renders it into the dashboard UI.

## Dashboards & Widgets

**Dashboard**
- A container for layout, shared filters, and widget configuration.
- Responsible for composition and reuse of dashboard layouts.

**Widget**
- A visual unit (chart, table, single value) backed by a data request.
- Each widget describes what it needs, but does not know how data is fetched.

**Filters and Layouts**
- Filters are passed through as generic values.
- Layout is a configuration concern (positions, sizes, grouping).
- DashKit does not validate filter meaning or enforce data semantics.

## Data Provider Interface

DashKit integrates with any backend through a pluggable data provider. The provider receives normalized requests and returns datasets in a generic structure.

Minimal interface sketch:

```ruby
class MyProvider
  # request is a plain object or hash describing widget intent
  def fetch(request)
    # return a dataset hash
  end
end
```

DashKit does not care how data is fetched. It only requires that the provider responds to requests and returns datasets that match the contract.

## Dataset Contract

DashKit renders datasets with a predictable structure, while leaving meaning and correctness to the provider.

Example dataset:

```json
{
  "series": [
    { "name": "Revenue", "points": [ { "x": "2024-01", "y": 120 } ] }
  ],
  "rows": [ { "label": "Total", "value": 120 } ],
  "meta": { "unit": "USD" }
}
```

DashKit expects:

- Consistent keys and array shapes per widget type.
- Values that can be rendered without additional interpretation.

DashKit does **not** define:

- What series or rows mean.
- Which fields are required beyond a widget’s renderer.
- How values are derived.

## Installation

Add the gem to your Gemfile:

```ruby
gem "dash_kit", github: "DYB-Development/dash_kit"
```

Run the install generator:

```bash
bundle install
rails generate dash_kit:install
rails db:migrate
```

The generator creates the migration, initializer, and engine route. You still need to complete these manual steps:

### 1. Add the association to your owner model

```ruby
# app/models/account.rb (or whichever model owns dashboards)
has_many :dash_kit_configurations, class_name: "DashKit::Configuration",
         as: :owner, dependent: :destroy
```

### 2. Pin sortablejs for drag-and-drop reordering

```ruby
# config/importmap.rb
pin "sortablejs"
```

### 3. Register Stimulus controllers

```js
// app/javascript/controllers/index.js
import { registerControllers as registerDashKitControllers } from "dash_kit/index"
registerDashKitControllers(application)
```

### 4. Configure the initializer

```ruby
# config/initializers/dash_kit.rb
DashKit.parent_controller = "ApplicationController"
DashKit.current_owner_method = :current_account

DashKit.configure do |config|
  config.register(:home) do |d|
    d.widget :on_deck, label: "On Deck", partial: "widgets/home/on_deck"
    d.widget :tasks,   label: "Tasks",   partial: "widgets/home/tasks"
  end
end
```

- `parent_controller` — the controller DashKit inherits from (gives it access to authentication and helpers)
- `current_owner_method` — the method DashKit calls to scope configurations to the current owner

### 5. Create a dashboard controller and view

```ruby
# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  def show
    @dashboard_config = DashKit::Configuration.for_owner(current_account, :home)
    @dashboard_config.save! if @dashboard_config.new_record?
  end
end
```

```erb
<%# app/views/dashboard/show.html.erb %>
<%= dash_kit_settings_button_attributes %>
<%= dash_kit_settings_modal(config: @dashboard_config) %>

<div class="mt-4 space-y-6">
  <% @dashboard_config.ordered_visible_widgets.each do |widget_key| %>
    <%= render "widgets/widget_frame", widget_key: widget_key %>
  <% end %>
</div>
```

## Design Philosophy

DashKit avoids data semantics by design. It treats datasets as opaque structures that can be rendered consistently, allowing teams to replace or evolve backends without rewriting dashboards. This deliberate decoupling keeps DashKit focused, composable, and stable over time.
