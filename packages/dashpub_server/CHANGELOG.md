## 0.0.3

- Implemented checking registry-wide setting `publicAccess` inside package access endpoints (`getVersions`, `getVersion`, `download`, `getPackageDetail`). Unauthenticated requests are now rejected with `401 Unauthorized` if global public access is disabled.
- Consolidated error handling to return `401 Unauthorized` for anonymous users lacking permissions, and `403 Forbidden` for authenticated but unauthorized requests.
- Added comprehensive unit tests asserting behavior for private/public package retrieval under different global `publicAccess` settings.

## 0.0.2

- Added a documentation.

## 0.0.1

- Initial release of the Dashpub Server.
