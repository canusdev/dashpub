# Contributing to Dashpub

Thank you for your interest in contributing to Dashpub! This guide will help you get started.

## Code of Conduct

Please adhere to the [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct/) in all interactions.

## Project Structure

Dashpub is a monorepo managed by [Melos](https://melos.invertase.dev/).

- `packages/dashpub_ui`: The Flutter frontend.
- `packages/dashpub_api`: Shared Dart API models and client.
- `packages/dashpub_server`: The Dart backend server.
- `packages/dashpub_cli`: The command-line interface.

## Getting Started

### Prerequisites

- Flutter SDK
- Melos (`dart pub global activate melos`)

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/canusdev/dashpub.git
   cd dashpub
   ```

2. Bootstrap the project:
   ```bash
   melos bootstrap
   ```

## Workflow

1. Create a new branch for your feature or fix.
2. Make your changes in the relevant packages.
3. Run tests using Melos:
   ```bash
   melos run test:all
   ```
4. Analyze the code:
   ```bash
   melos run analyze
   ```
5. Format the code:
   ```bash
   melos run format
   ```

## Pull Requests

- Use clear and descriptive titles.
- Reference related issues.
- Ensure all CI checks pass.

Thank you for contributing!
