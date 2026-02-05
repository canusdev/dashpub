<p align="center">
  <img src="doc/dashpub.png" alt="Dashpub Logo" width="200" />
</p>

<p align="center">
  <a href="https://github.com/sponsors/canusdev">
    <img src="https://img.shields.io/github/sponsors/canusdev?style=social&logo=github" alt="Sponsor" />
  </a>
</p>

# Dashpub

Dashpub is a modern, private Dart package registry and dashboard. It offers a refreshed UI, improved performance, and a robust API for managing your private Dart and Flutter packages.

## Features

- **Private Registry**: Host your own Dart packages securely with full dependency resolution support.
- **Modern UI**: A sleek, responsive dashboard built with `shadcn_flutter`, featuring dark mode and mobile support.
- **Team Management**:
  - Create and manage organizations/teams.
  - Granular role-based access control (Admin, Member).
- **Admin Control Panel**:
  - **User Management**: View and manage all registered users.
  - **Package Management**: Administer all packages, deprecate versions, or remove packages.
  - **System configuration**: Manage global settings and permissions.
- **Package Discovery**:
  - Advanced search with filters.
  - Detailed package pages with Readme, Changelog, Example, and Installing tabs.
  - Version history and dependency graphs.
- **Setup Wizard**: Easy-to-use initial configuration flow for setting up the instance.
- **Monorepo Architecture**: Specific, isolated packages for API, CLI, Server, and UI.

## TODO

- [ ] **Email Integration**: Invite members via email and email verification.
- [ ] **Light Theme**: Add light theme for the UI.
- [ ] **Package Analysis**: Automated scoring and static analysis for uploaded packages.
- [ ] **CI/CD Integration**: Webhooks and better CLI tokens for CI pipelines.
- [ ] **Webpush Integration**: Notifications for package updates using Web Push.
- [ ] **Cloud Storage**: Support for S3 and Google Cloud Storage (GCS) for package binaries.
- [ ] **Dynamic Site Settings**: Configure site title, logo, and other static assets from the UI.
- [ ] **Periodic Backups**: Automated database and storage backups.

## Architecture

This project is a monorepo managed by [Melos](https://melos.invertase.dev/).

- **[`dashpub_ui`](packages/dashpub_ui)**: The Flutter-based web dashboard.
- **[`dashpub_server`](packages/dashpub_server)**: The Dart backend server (Shelf + MongoDB).
- **[`dashpub_api`](packages/dashpub_api)**: Shared Dart models and API client.
- **[`dashpub_cli`](packages/dashpub_cli)**: The command-line tool for publishing and managing packages.

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Melos](https://melos.invertase.dev/) (`dart pub global activate melos`)
- MongoDB (for the server)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/canusdev/dashpub.git
   cd dashpub
   ```

2. **Bootstrap the project:**
   ```bash
   melos bootstrap
   ```

3. **Run the Server:**
   Navigate to `packages/dashpub_server` and run:
   ```bash
   dart bin/server.dart
   ```

4. **Run the UI:**
   Navigate to `packages/dashpub_ui` and run:
   ```bash
   flutter run -d chrome
   ```

### Docker Deployment
#### Build locally
To deploy Dashpub using Docker Compose building from source:

1. **Run the services:**
   ```bash
   docker-compose up -d --build
   ```

#### Use Pre-built Image (GHCR)
You can directly run Dashpub using the pre-built image from GitHub Container Registry.

Create a `docker-compose.yml`:

```yaml
version: '3'
services:
  dashpub:
    image: ghcr.io/canusdev/dashpub:latest
    ports:
      - "4000:4000"
    environment:
      - DASHPUB_MONGO_URL=mongodb://mongo:27017/dashpub
      - DASHPUB_STORAGE_PATH=/data
      # - DASHPUB_GOOGLE_CLIENT_ID=... # Optional
    volumes:
      - dashpub_data:/data
    depends_on:
      mongo:
        condition: service_healthy

  mongo:
    image: mongo:6.0
    ports:
      - "27017:27017"
    volumes:
      - mongo_data:/data/db
    healthcheck:
      test: echo 'db.runCommand("ping").ok' | mongosh localhost:27017/test --quiet
      interval: 10s
      timeout: 10s
      retries: 5

volumes:
  dashpub_data:
  mongo_data:
```

#### Docker Run (Manual)
If you prefer running manual commands:

1. Create a network:
   ```bash
   docker network create dashpub-net
   ```
2. Run MongoDB:
   ```bash
   docker run -d --name mongo --network dashpub-net mongo:6.0
   ```
3. Run Dashpub:
   ```bash
   docker run -d --name dashpub \
     -p 4000:4000 \
     --network dashpub-net \
     -v $(pwd)/dashpub_data:/data \
     -e DASHPUB_STORAGE_PATH=/data \
     -e DASHPUB_MONGO_URL=mongodb://mongo:27017/dashpub \
     ghcr.io/canusdev/dashpub:latest
   ```

2. **Access the service:**
   The server will be available at `http://localhost:4000`.

   **Environment Variables:**
   - `DASHPUB_MONGO_URL`: MongoDB connection string.
   - `DASHPUB_STORAGE_PATH`: Storage path for packages.

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to get started.

## License

Dashpub is licensed under the [GNU Affero General Public License v3.0 (AGPLv3)](LICENSE).

<p align="center">
  Built with ❤️ by Can US
</p>
