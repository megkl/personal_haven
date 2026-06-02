# Personal Haven – repository image
# Flutter 3.38.7 / Dart 3.10.7
FROM ghcr.io/cirruslabs/flutter:3.38.7

WORKDIR /app

# Install system dependencies needed for Flutter Linux/headless builds
RUN apt-get update && \
    apt-get install -y --no-install-recommendations \
        git \
        curl \
        unzip \
        xz-utils \
        libglu1-mesa \
        wget && \
    rm -rf /var/lib/apt/lists/*

# Copy project files
COPY . .

# Accept Android licenses non-interactively and fetch dependencies
RUN flutter config --no-analytics && \
    flutter pub get

# Default working directory for tasks
WORKDIR /app
