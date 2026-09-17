# Changelog

## [Unreleased]

## [2.0.0] - 2026-09-17

### Changed
- A dashboard keeps its widgets as a saved layout on a grid, each widget carrying the column and row it sits at and the columns and rows it spans, in place of an order of widget keys and a list of hidden ones.
- A widget type is registered with the size it takes on a desktop and the size it takes on a screen narrower than 640 pixels, and neither can be changed by whoever arranges the dashboard. A type registered with no size takes the full width and four rows.
- A widget someone built in the app sits on the grid like any other widget, and is placed there when it is built.
- A dashboard holds at most one widget of any one type.

### Removed
- The window for reordering widgets by dragging rows, and the ways of moving a widget up, moving it down, hiding it and reordering the whole list. A dashboard is arranged on the dashboard itself.

### Upgrading
- Dashboards are not migrated. A host sets its dashboards up again after upgrading: the columns holding the old order and the hidden list are gone, and the layout starts empty.
- Give each registered widget type a `width` and `height`, and a `narrow_width` and `narrow_height` for phones. A type without them takes the full width.
- Remove the `sortablejs` pin from the host's importmap, which DashKit no longer uses.
