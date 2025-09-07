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

# Use a newer version of Flutter
ENV FLUTTER_VERSION=3.35.3
ENV FLUTTER_HOME=/opt/flutter
ENV PATH=$PATH:$FLUTTER_HOME/bin

# Clone the specified Flutter version
RUN git clone --branch $FLUTTER_VERSION https://github.com/flutter/flutter.git $FLUTTER_HOME

# 1. Create the user first.
RUN useradd -ms /bin/bash flutteruser

# 2. Now, change the ownership of the Flutter SDK directory to the user you just created.
RUN chown -R flutteruser:flutteruser /opt/flutter

# 3. Switch to the non-root user
USER flutteruser
WORKDIR /home/flutteruser/app

# Pre-run flutter doctor to populate the cache as the correct user.
RUN flutter doctor

# Copy pubspec.yaml and get dependencies as the non-root user
COPY --chown=flutteruser:flutteruser flutter_app/pubspec.yaml ./
RUN flutter pub get

# Copy the rest of the source code
COPY --chown=flutteruser:flutteruser flutter_app/ ./

# === FIX: Use the modern build command ===
# Build for web as the non-root user, removing the obsolete flag.
RUN flutter build web --release

# ==========================================================
# Production stage with nginx
FROM nginx:alpine

# Copy built web app from the specific user's home directory
COPY --from=flutter-builder /home/flutteruser/app/build/web /usr/share/nginx/html

# Simple nginx configuration for serving static files
# (Your nginx config is good)
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