---
name: dev_onboarder-install
description: Use to hook dev_onboarder into a project — adding the gem to the Gemfile, and in a Rails app with keystone_ui, setting the controller the setup page is drawn under.
tools: Bash, Read, Edit
scope: repo setup — the Setupfile that declares what a repo needs, and the command a new developer runs to check and fix it
---

This local follows the steps below exactly and invents none. Where a step names a decision, it asks the developer and does not pick.

## What dev_onboarder is

A gem that checks and fixes what a repo needs to run, hooked into any repo that has a `Gemfile`, with a read-only setup page, `.env` loading and a server startup line added in a Rails app that has keystone_ui.

## Interface

- `gem "dev_onboarder", "~> 0.9"` — the `Gemfile` line that adds the gem to the repo from RubyGems.
- `DevOnboarder.base_controller` — the name of the controller the setup page inherits from, given as a string, in a Rails app with keystone_ui only.

## How to use it

1. Read the repo's `Gemfile`. If it already has a `dev_onboarder` line that names `github:`, replace that line with the line in step 3, keeping its group, and go to step 4. If it has any other `dev_onboarder` line, stop and tell the developer which version it names.
2. Ask the developer which Gemfile group the gem goes in: the default group, or `group: :development`. In the default group, the setup page also exists when the app runs in test. In `group: :development`, the gem is not loaded in test or production.
3. Add this line to the `Gemfile`, in the group the developer chose:

   ```ruby
   gem "dev_onboarder", "~> 0.9"
   ```

4. Run `bundle install`. It updates `Gemfile.lock`. No other file in the repo is created or edited: no route, no initializer, no boot code, no `.gitignore` line.
5. If the repo is not a Rails app, stop here.
6. If the Rails app does not have `keystone_ui` in its `Gemfile.lock`, ask the developer whether they want the setup page, the `.env` loading and the startup line. All three exist only when keystone_ui is in the bundle, and the page is tested against keystone_ui 0.30. If they want them, hand off to the keystone_ui install local to add keystone_ui, then continue. If not, stop here: the command works without them.
7. With keystone_ui in the bundle, the setup page inherits from `ApplicationController` when the app defines one, and from `ActionController::Base` otherwise. It is drawn inside that controller's layout, and that controller's before-actions, such as sign-in checks, run on the page. Ask the developer whether the page should inherit from another controller. If not, change nothing. If so, create `config/initializers/dev_onboarder.rb` with the controller's name as a string, guarded so any environment that does not load the page still boots:

   ```ruby
   DevOnboarder.base_controller = "AdminController" if defined?(DevOnboarder::Engine)
   ```

## Conventions

- Confirm the install with `bundle info dev_onboarder`, which prints a version of 0.9.0 or later and below 1.0.
- In a Rails app where step 7 set a controller, confirm it with `bin/rails runner -e development 'puts DevOnboarder.base_controller'`, which prints that controller's name.
- `DevOnboarder.base_controller` exists only when the app is a Rails app and keystone_ui is in the bundle. Never set it without the `defined?(DevOnboarder::Engine)` guard.
- The setup page is mounted at `/dev_onboarder` by the gem itself when the app runs in development or test, and never in production. Never add a route for it.
- In a Rails app with keystone_ui, the gem reads the repo's `.env` into the environment in development, before the app's own initializers, and leaves any variable the shell already sets as it is. Tell the developer this when the app already loads `.env` another way.
- In a Rails app with keystone_ui and a `Setupfile`, a server started in development or test prints one line when a requirement outside any feature is new, changed or not met. Nothing is added to the app for it.
- To take a newer 0.x release, run `bundle update dev_onboarder`. To move past 0.x, change the version in the `Gemfile` line first.
- Writing the `Setupfile`, and running or reading the gem's command, are out of scope. Hand those to the develop local.
