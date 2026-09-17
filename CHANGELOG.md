# Changelog

## [Unreleased]

### Fixed
- Adding a widget from the block list, removing one, and reading a dashboard's layout back all work. The grid asked for these as it was built to, and nothing answered, so its Add and Remove buttons did nothing and a saved move never came back to the page.

## [2.0.0] - 2026-09-17

### Changed
- A dashboard a viewer may edit is the grid: widgets are moved by the handle each one carries, every move is saved as it is made, and a finger anywhere else on a widget scrolls the page. A viewer who may not edit sees the same dashboard with nothing to take hold of.
- A dashboard keeps its widgets as a saved layout on a grid, each widget carrying the column and row it sits at and the columns and rows it spans, in place of an order of widget keys and a list of hidden ones.
- A widget type is registered with the size it takes on a desktop and the size it takes on a screen narrower than 640 pixels, and neither can be changed by whoever arranges the dashboard. A type registered with no size takes the full width and four rows.
- A widget someone built in the app sits on the grid like any other widget, and is placed there when it is built.
- A dashboard holds at most one widget of any one type.

### Removed
- Ruby 3.2. The gem asks for Ruby 3.3 or later, which is what its browser tests need.
- The window for reordering widgets by dragging rows, and the ways of moving a widget up, moving it down, hiding it and reordering the whole list. A dashboard is arranged on the dashboard itself.

### Upgrading
- A host that drew its own list of widgets calls `dash_kit_render_widgets(config:)` instead: the ways of reading a dashboard's widget order, of asking whether a widget is hidden, and of drawing the settings window and its button are all gone.
- A dashboard is a section of a host's page, not the page, and a page may carry more than one.
- Dashboards are not migrated. A host sets its dashboards up again after upgrading: the columns holding the old order and the hidden list are gone, and the layout starts empty.
- Give each registered widget type a `width` and `height`, and a `narrow_width` and `narrow_height` for phones. A type without them takes the full width.
- Remove the `sortablejs` pin from the host's importmap, which DashKit no longer uses.
- Load the two scripts the grid needs on any page that draws a dashboard: `javascript_include_tag "keystone_ui/react"` and `javascript_include_tag "dash_kit/dashboard_grid"`, plus `stylesheet_link_tag "dash_kit/dashboard_grid"`.
