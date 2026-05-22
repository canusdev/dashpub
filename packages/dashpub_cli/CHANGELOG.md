# Changelog
## 0.0.3

- Added support for direct login using an existing API token via the `--token` / `-t` option in the `login` command.
- Standardized command inputs by stripping trailing slashes from the registry URL option in all commands (`login`, `publish`, `token`).
- Added unit tests for token-based authentication (success and failure scenarios).

## 0.0.2

- Added comprehensive documentation and library exports.
- Added example usage script.
- Updated `archive` dependency to `^4.0.0`.
- Updated package description.
## 0.0.1

- Initial release of the Dashpub CLI companion.
- Implemented `login` command with persistent token storage.
- Implemented `publish` command for uploading package archives to the registry.
- Migrated to the unified `DashpubApiClient` for consistent communication.
- Standardized environment variables and configuration patterns.
