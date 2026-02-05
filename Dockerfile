# Stage 1: Build Flutter Web
FROM dart:stable AS ui-build

# Install Flutter
RUN apt-get update && apt-get install -y git curl zip unzip libglu1-mesa xz-utils
RUN curl -o flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.38.9-stable.tar.xz \
    && tar xf flutter.tar.xz -C /usr/local \
    && rm flutter.tar.xz
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"
RUN git config --global --add safe.directory /usr/local/flutter
RUN flutter config --no-analytics
RUN flutter precache --web

WORKDIR /app
COPY . .

WORKDIR /app/packages/dashpub_ui
RUN flutter pub get
RUN flutter build web --release --wasm

# Stage 2: Build Dart Server
FROM dart:stable AS server-build

WORKDIR /app
COPY --from=ui-build /app /app

WORKDIR /app/packages/dashpub_server
RUN dart pub get
# Generate models and routes
RUN dart run build_runner build --delete-conflicting-outputs
# Compile server
RUN dart compile exe bin/dashpub_server.dart -o bin/server

# Stage 3: Runtime
FROM dart:stable

WORKDIR /app

# Install dependencies for Flutter/Dart
RUN apt-get update && apt-get install -y git curl zip unzip libglu1-mesa xz-utils

# Copy Flutter SDK from ui-build
COPY --from=ui-build /usr/local/flutter /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"
RUN git config --global --add safe.directory /usr/local/flutter

# Copy compiled server
COPY --from=server-build /app/packages/dashpub_server/bin/server /app/server
# Copy builtin UI assets
COPY --from=ui-build /app/packages/dashpub_ui/build/web /app/ui

# Environment variables
ENV PORT=4000
ENV DASHPUB_MONGO_URL=mongodb://mongo:27017/dashpub
ENV DASHPUB_STORAGE_PATH=/data
ENV DASHPUB_STATIC_ASSETS_PATH=/app/ui

EXPOSE 4000

CMD ["/app/server"]
