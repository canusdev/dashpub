<p align="center">
  <img src="../../doc/dashpub.png" alt="Dashpub Logo" width="200" />
</p>

<p align="center">
  <a href="https://github.com/sponsors/canusdev">
    <img src="https://img.shields.io/github/sponsors/canusdev?style=social&logo=github" alt="Sponsor" />
  </a>
</p>

# Dashpub API

Client library and shared models for interacting with the Dashpub Package Registry.

## Features

This package provides a comprehensive client wrapper for the Dashpub API, enabling:

- **Authentication**: Login, register, and manage user sessions.
- **Package Discovery**: List, search, filter, and retrieve package details.
- **Publishing**: Upload and publish new package versions programmatically.
- **Management**: Manage teams, users, and global settings (admin capabilities).

## Installation

Add `dashpub_api` to your `pubspec.yaml`:

```yaml
dependencies:
  dashpub_api: ^1.0.0
```

## Usage

### Initialization

Initialize the `DashpubApiClient` with the base URL of your Dashpub server.

```dart
import 'package:dashpub_api/dashpub_api.dart';

void main() {
  final client = DashpubApiClient('https://pub.yourdomain.com');
  // ...
}
```

### Authentication

Login to retrieve an authentication token and user details.

```dart
try {
  final authResponse = await client.login('user@example.com', 'supersecret');
  print('Logged in as: ${authResponse.user.email}');
  
  // The client stores the token internally for subsequent requests, 
  // but you can also set it manually if you have a persisted token.
  client.setToken(authResponse.token);
} catch (e) {
  print('Login failed: $e');
}
```

### Fetching Packages

Retrieve a list of packages with optional filtering and sorting.

```dart
final listApi = await client.getPackages(
  size: 20,
  page: 0,
  sort: 'download', // or 'updated'
  q: 'search query',
);

for (var pkg in listApi.packages) {
  print('${pkg.name} - v${pkg.latest}');
}
```

### Getting Package Details

Get detailed validation and metadata for a specific package.

```dart
final details = await client.getPackageDetail('my_package');
print('Description: ${details.description}');
print('Latest Version: ${details.version}');
```

### Publishing a Package

Publish a new version by providing the `tar.gz` bytes.

```dart
import 'dart:io';

// Read your package archive
final bytes = await File('package.tar.gz').readAsBytes();

await client.publish(bytes);
print('Package published successfully!');
```

## Architecture

This package exports shared Data Transfer Objects (DTOs) used by both the server and client:
- `ListApi`: Response format for package listing.
- `WebapiDetailView`: Detailed package metadata.
- `User`: User profile information.
- `Team`: Team data structure.

These models are serializable using `json_serializable`.
