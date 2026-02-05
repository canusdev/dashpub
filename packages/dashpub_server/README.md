<p align="center">
  <img src="../../doc/dashpub.png" alt="Dashpub Logo" width="200" />
</p>

<p align="center">
  <a href="https://github.com/sponsors/canusdev">
    <img src="https://img.shields.io/github/sponsors/canusdev?style=social&logo=github" alt="Sponsor" />
  </a>
</p>

# Dashpub Server

The backend service for Dashpub, a private Dart package registry. It provides a Pub-compliant API for the Dart `pub` client and a custom API for the Dashpub UI.

## Docker Deployment
For deployment instructions, including how to run with Docker/Docker Compose, please refer to the [Main Repository README](https://github.com/canusdev/dashpub/blob/main/README.md#docker-deployment).

## Features

- **Pub API API**: Fully compatible with `dart pub` for publishing and retrieving packages.
- **Web API**: REST API for the Dashpub frontend (Search, Details, Manage).
- **Authentication**: JWT-based authentication with support for API tokens.
- **Authorization**: Granular package permissions (Uploaders, Teams).
- **Storage**: Pluggable storage (Local File System, could be extended to S3/GCS).
- **Database**: MongoDB for metadata storage.
- **CORS Support**: Configurable CORS for cross-origin frontend access.

## Getting Started

### Prerequisites

- Dart SDK (latest stable)
- MongoDB instance

### Installation

1. **Get dependencies**:
   ```bash
   dart pub get
   ```

2. **Run the server**:
   ```bash
   dart run bin/dashpub_server.dart
   ```

## Configuration

The server is configured via environment variables.

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | The port to listen on. | `4000` |
| `DASHPUB_MONGO_URL` | MongoDB connection string. | `mongodb://localhost:27017/dashpub` |
| `DASHPUB_STORAGE_PATH` | Directory path for storing package archives. | `./data` |
| `DASHPUB_STATIC_ASSETS_PATH` | Path to static assets (frontend build) to serve. | `null` (disabled) |
| `DASHPUB_SECRET_KEY` | Secret key for signing JWTs. | *Hardcoded default (change in prod)* |
| `DASHPUB_STORAGE_DRIVER` | Storage backend (`file` or `s3`). | `file` |
| `DASHPUB_S3_ENDPOINT` | S3 API Endpoint (e.g., `s3.amazonaws.com`). | Required for `s3` |
| `DASHPUB_S3_BUCKET` | S3 Bucket Name. | Required for `s3` |
| `DASHPUB_S3_ACCESS_KEY` | S3 Access Key. | Required for `s3` |
| `DASHPUB_S3_SECRET_KEY` | S3 Secret Key. | Required for `s3` |
| `DASHPUB_S3_REGION` | S3 Region. | Optional |

### Example (File Storage)

```bash
export PORT=8080
export DASHPUB_MONGO_URL=mongodb://user:pass@mongo:27017/dashpub
export DASHPUB_STORAGE_PATH=/var/dashpub/packages
dart run bin/dashpub_server.dart
```

### Example (S3 Storage)

```bash
export DASHPUB_STORAGE_DRIVER=s3
export DASHPUB_S3_ENDPOINT=s3.amazonaws.com
export DASHPUB_S3_BUCKET=my-dashpub-bucket
export DASHPUB_S3_ACCESS_KEY=AKIA...
export DASHPUB_S3_SECRET_KEY=secret...
export DASHPUB_S3_REGION=us-east-1
dart run bin/dashpub_server.dart
```

## Running with Docker

It is recommended to run Dashpub using Docker Compose from the root of the repository.

```yaml
services:
  dashpub:
    image: ghcr.io/canusdev/dashpub:latest
    ports:
      - "4000:4000"
    environment:
      - DASHPUB_MONGO_URL=mongodb://mongo:27017/dashpub
    volumes:
      - dashpub_data:/app/data
```

## API Documentation

### Pub API

- `GET /api/packages/<name>`: Get package versions.
- `GET /api/packages/<name>/versions/<version>`: Get specific version.
- `GET /packages/<name>/versions/<version>.tar.gz`: Download package archive.
- `GET /api/packages/versions/new`: Initiate upload (for `dart pub publish`).
- `POST /api/packages/versions/new-upload`: Upload package file.
- `GET /api/packages/versions/new-upload-finish`: Finalize upload.

### Web API

- `GET /webapi/packages`: List packages with pagination and search.
- `GET /webapi/package/<name>/<version>`: Detailed package info for UI.

### Auth API

- `POST /api/auth/register`: Register a new user (first user is Admin).
- `POST /api/auth/login`: Login and get JWT.
- `GET /api/auth/me`: Get current user profile.
- `PATCH /api/auth/me`: Update profile.
- `POST /api/auth/token`: Generate a persistent API token.

### Admin/Management API

- `GET /api/teams`: List user's teams.
- `POST /api/teams`: Create a team.
- `GET /api/admin/users`: List all users (Admin only).
- `GET /api/admin/teams`: List all teams (Admin only).
