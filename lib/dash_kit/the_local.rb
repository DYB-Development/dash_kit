# frozen_string_literal: true

require "dash_kit/reference"

begin
  require "the_local"

  TheLocal.register(
    "dash_kit",
    prefix: "dash_kit",
    scope: "composable, configurable Rails dashboards and widgets",
    agents_dir: File.expand_path("the_local/agents", __dir__)
  ) do |c|
    c.agent "info",
      description: "Use to learn what DashKit is, what it does and does not do, and its architecture (widget registry, Dashboard, helpers, routes).",
      tools: "Read",
      body: "You explain DashKit, answering only from the reference: what it is, what it deliberately is not, its widget registry, the Dashboard model, the WidgetManagement concern, the view helpers, the engine routes, and the Turbo lazy-load data flow. You make no changes.",
      knowledge: DashKit::Reference.content

    c.agent "install",
      description: "Use to set DashKit up in a host Rails app: add the gem, run the install generator, mount the engine, configure the initializer, wire the owner association, importmap, and Stimulus controllers.",
      tools: "Read, Edit, Write, Bash",
      body: "You install DashKit into a host Rails app, following only the reference's installation steps. You add the gem, run the install generator, migrate, mount the engine, then complete the manual wiring: the polymorphic owner association, the sortablejs importmap pin, the Stimulus controller registration, and the initializer (parent_controller, current_owner_method, and registered dashboards/widgets). You set up a dashboard controller and view that scope to the current owner. You do not invent configuration the reference does not describe.",
      knowledge: DashKit::Reference.content

    c.agent "develop",
      description: "Use to build dashboards and widgets with DashKit in a host app: register widget types, write widget partials, render and lazy-load them, and persist per-owner visibility, order, and filters correctly.",
      tools: "Read, Edit, Write, Bash",
      body: "You build dashboards and widgets with DashKit, following the reference's conventions. You register dashboard types and widgets in DashKit.configure, write self-contained widget partials that fetch their own data, render through dash_kit_render_widgets so widgets lazy-load in Turbo Frames, and always scope dashboards to the current owner via Dashboard.for_owner. You persist preferences through the WidgetManagement methods and engine routes rather than writing JSON columns by hand. You never make DashKit query data or enforce metric semantics — those belong to the host.",
      knowledge: DashKit::Reference.content
  end
rescue LoadError
  # the_local is a build-time-only dependency; the gem works without it.
end
