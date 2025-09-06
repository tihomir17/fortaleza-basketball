# Fortaleza Basketball Analytics - Frontend Deployment

This document provides instructions for deploying the Fortaleza Basketball Analytics frontend application.

## Prerequisites

- Docker and Docker Compose installed
- Flutter SDK (for local builds)
- Access to the backend API

## Quick Deployment

### Option 1: Docker Compose (Recommended)

```bash
# Build and start the frontend
docker-compose up -d --build

# Check status
docker-compose ps

# View logs
docker-compose logs -f frontend
```

### Option 2: Docker Build

```bash
# Build the Docker image
docker build -t fortaleza-frontend .

# Run the container
docker run -d -p 8080:80 --name fortaleza-frontend fortaleza-frontend
```

### Option 3: Local Flutter Build

```bash
# Make build script executable
chmod +x build.sh

# Run the build script
./build.sh

# The built files will be in flutter_app/build/web/
```

## Configuration

### Environment Variables

The frontend connects to the backend API. Make sure the backend is running and accessible.

### API Configuration

The API base URL is configured in `flutter_app/lib/core/api/api_client.dart`. For production, update this to point to your backend server.

### Nginx Configuration

The `nginx.conf` file includes:
- Gzip compression
- Security headers
- Static asset caching
- Flutter web app routing support
- Health check endpoint

## Production Deployment

### With Traefik (Reverse Proxy)

The docker-compose.yml includes Traefik labels for automatic SSL and reverse proxy configuration:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.frontend.rule=Host(`your-domain.com`)"
  - "traefik.http.routers.frontend.tls=true"
  - "traefik.http.routers.frontend.tls.certresolver=letsencrypt"
```

### Manual Nginx Setup

If using a manual Nginx setup, use the provided `nginx.conf` as a reference.

## Health Checks

The application includes a health check endpoint at `/health` that returns "healthy" when the service is running.

## Monitoring

### Logs

```bash
# View application logs
docker-compose logs -f frontend

# View Nginx access logs
docker exec fortaleza-frontend tail -f /var/log/nginx/access.log

# View Nginx error logs
docker exec fortaleza-frontend tail -f /var/log/nginx/error.log
```

### Health Check

```bash
# Check if the service is healthy
curl http://localhost:8080/health
```

## Troubleshooting

### Common Issues

1. **Build fails**: Ensure Flutter SDK is properly installed and in PATH
2. **API connection issues**: Verify backend is running and accessible
3. **Routing issues**: Check that Nginx is properly configured for SPA routing
4. **Performance issues**: Enable gzip compression and static asset caching

### Debug Mode

For debugging, you can run the Flutter app in debug mode:

```bash
cd flutter_app
flutter run -d web-server --web-port 8080
```

## Security Considerations

- The application includes security headers in the Nginx configuration
- Static assets are cached for performance
- Hidden files are denied access
- CORS is handled by the backend

## Performance Optimization

- Gzip compression is enabled
- Static assets are cached for 1 year
- Flutter web renderer is set to HTML for better compatibility
- Build is optimized for production with `--release` flag

## Scaling

For high-traffic deployments:

1. Use a load balancer (nginx, traefik, etc.)
2. Scale horizontally with multiple container instances
3. Use a CDN for static assets
4. Implement Redis caching for API responses

## Backup and Recovery

The frontend is stateless, so no data backup is required. However, keep backups of:
- Docker images
- Configuration files
- SSL certificates (if using manual setup)
