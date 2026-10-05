---
name: dev_onboarder-info
description: Use to learn what dev_onboarder offers — declaring what a repo needs to run, checking and fixing it from one command, per-feature setup, the record of the last run, and the local setup page and startup notice in a Rails app.
tools: Read
scope: repo setup — the Setupfile that declares what a repo needs, and the command a new developer runs to check and fix it
---

This local explains what dev_onboarder is and the words its other two locals use. It makes no changes and gives no steps.

## What dev_onboarder is

dev_onboarder takes a developer from a fresh clone to a working repo with one command. The repo lists what it needs in one file at its root: databases that exist, programs on the path at a minimum version, the Ruby the repo names, Homebrew packages, environment variables, key files. The command checks each need, runs the repo's own fix for any that are not met, asks for the value of a missing variable, checks again, and says what is still missing and who to ask.

Reach for it when a repo's setup lives in a README, in someone's memory, or in a script that stops at the first failure. It works in any repo, Rails or not, through the command alone. A Rails app that also has keystone_ui gets three more things: it reads the `.env` file in development before the app's initializers run, it prints one line at local server start when needs outside any feature are new, changed or not met, and it gets a read-only page showing the last run, which exists only when the app runs locally. A Rails app without keystone_ui gets none of the three. Adding the gem changes no other file in the repo.

## Interface

This local declares no commands. The other two locals own the whole surface:

- **install** owns adding the gem to a repo and the one setting a Rails app can change, the controller the setup page is drawn under.
- **develop** owns everything written in the setup file, each kind of declaration, and every command a developer runs.

## How to use it

- The gem is not in the repo yet, or the setup page needs a different controller: use the install local.
- The repo has the gem and you need to declare a need, group needs under a feature, or run, read or explain the command: use the develop local.
- Neither: the answer is in this page.

## Conventions

- **Setup file** — the Ruby file at the repo's root, named in the scope line above, where every need is declared. One declaration per need.
- **Requirement** — one need, identified by a key that must be unique across the file. It carries a group, a one-line purpose, and a check. It may carry a fix, an instruction, and a time limit on the fix in seconds.
- **Check** — a shell command that exits zero when the requirement is met.
- **Fix** — a shell command run when the check fails, after which the check runs again.
- **Instruction** — text shown when the requirement is still not met, usually who to ask.
- **Group** — a label that sorts requirements for display. Built-in declarations use `machine_tools` for programs, Ruby and Homebrew packages, and `secrets` for environment variables and key files. Others are chosen by the repo.
- **Optional** — a variable that is listed when missing and never fails a run.
- **Met / not met** — the result of one requirement's check on the last run.
- **Feature** — a named group of requirements needed only to test one part of the app. A plain run checks them, runs none of their fixes, and does not fail on them. A feature is **ready** when none of its requirements is new, changed or not met.
- **Setup record** — what the last run found, kept inside the clone's git directory so it is never committed, or at the repo's root outside git. Each git worktree keeps its own. A run writes it once, at the end.
- **New / changed / not met** — the three states a status report shows by comparing the setup file with the setup record. A requirement is **changed** when its check, fix or instruction differs from what the last run recorded.
- **Setup page** — the read-only page in a Rails app with keystone_ui. It shows the setup record and runs no check and no fix.
- **Startup notice** — the one line a local Rails server with keystone_ui prints at start, counting the needs outside any feature that need setup.
