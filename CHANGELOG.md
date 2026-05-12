# Changelog

## v1.1.0 - 2026-05-12

### Added

- Added the drag-and-run `start-here.cmd` setup menu for Windows users.
- Added a selective install flow so users can confirm modules before installation.
- Added environment setup actions for Git, Node.js, Claude Code, cc-switch, and engine tooling.
- Added a guarded removal flow that requires explicit confirmation before deleting installed items.
- Added the `zh-CN` language pack for the installer and setup menu.

### Improved

- Improved Unreal MCP setup guidance and Claude Code project configuration for `http://localhost:3000/mcp`.
- Improved dry-run coverage for Windows PowerShell and the drag-and-run launcher.
- Improved release safety with contract tests for setup, localization, MCP examples, and CI coverage.

### Fixed

- Fixed Windows PowerShell parser errors in installer heredoc content.
- Fixed setup menu switch binding so `-DryRun` works from interactive choices.
- Fixed strict config checks for Claude MCP settings in fresh projects.

## v1.0.1 - 2026-05-10

### Fixed

- Fixed CI PowerShell analysis path handling.
- Fixed installer dry-run validation for Windows environments.

## v1.0.0 - 2026-05-10

### Added

- Published the first stable course installer with engine manifests, MCP examples, and smoke-test documentation.
