# Multi-stage build for Flutter web app
FROM ubuntu:22.04 as flutter-builder

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
ENV FLUTTER_VERSION=3.24.5
ENV FLUTTER_HOME=/opt/flutter
ENV PATH=$PATH:$FLUTTER_HOME/bin

RUN git clone --branch $FLUTTER_VERSION https://github.com/flutter/flutter.git $FLUTTER_HOME
RUN flutter config --no-analytics
RUN flutter doctor

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY flutter_app/pubspec.yaml ./
#flutter_app/pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy source code
COPY flutter_app/ ./

# Build for web
RUN flutter build web --release --web-renderer html

# Production stage with nginx
FROM nginx:alpine

# Copy built web app
COPY --from=flutter-builder /app/build/web /usr/share/nginx/html

# Simple nginx configuration for serving static files
RUN echo 'server { \
    listen 80; \
    server_name _; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
    location /health { \
        access_log off; \
        return 200 "healthy\n"; \
        add_header Content-Type text/plain; \
    } \
}' > /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
