# Fortaleza Basketball Analytics - Deployment Checklist

## Pre-Deployment Checklist

### ✅ Environment Setup
- [ ] Docker and Docker Compose installed on deployment server
- [ ] Backend API is running and accessible
- [ ] Domain name configured (if using custom domain)
- [ ] SSL certificates ready (if using HTTPS)
- [ ] Firewall rules configured for port 80/443

### ✅ Configuration
- [ ] Update API base URL in `flutter_app/lib/core/api/api_client.dart`
- [ ] Update domain name in `docker-compose.yml` Traefik labels
- [ ] Review and update `nginx.conf` if needed
- [ ] Update `production.env` with correct values

### ✅ Security
- [ ] Review security headers in `nginx.conf`
- [ ] Ensure HTTPS is configured (if using custom domain)
- [ ] Verify CORS settings match backend configuration
- [ ] Check that sensitive files are in `.dockerignore`

## Deployment Steps

### 1. Upload Files
```bash
# Upload the entire frontend directory to your server
scp -r frontend/ user@your-server:/path/to/deployment/
```

### 2. Build and Deploy
```bash
# SSH into your server
ssh user@your-server

# Navigate to frontend directory
cd /path/to/deployment/frontend

# Make scripts executable
chmod +x deploy.sh build.sh

# Run deployment
./deploy.sh
```

### 3. Verify Deployment
```bash
# Check if services are running
docker-compose ps

# Test health endpoint
curl http://localhost:8080/health

# Test main application
curl http://localhost:8080/
```

## Post-Deployment Verification

### ✅ Application Tests
- [ ] Frontend loads correctly
- [ ] API connections work
- [ ] Authentication flow works
- [ ] All major features are accessible
- [ ] Mobile responsiveness works
- [ ] Performance is acceptable

### ✅ Monitoring Setup
- [ ] Health checks are working
- [ ] Logs are being generated
- [ ] Error monitoring is in place
- [ ] Performance monitoring is configured

### ✅ Backup and Recovery
- [ ] Docker images are backed up
- [ ] Configuration files are version controlled
- [ ] Recovery procedures are documented
- [ ] Rollback plan is ready

## Troubleshooting

### Common Issues

1. **Build Fails**
   - Check Flutter SDK version compatibility
   - Verify all dependencies are available
   - Check Docker build logs

2. **API Connection Issues**
   - Verify backend is running
   - Check API base URL configuration
   - Verify CORS settings

3. **Routing Issues**
   - Check Nginx configuration
   - Verify SPA routing is configured
   - Test direct URL access

4. **Performance Issues**
   - Enable gzip compression
   - Check static asset caching
   - Monitor resource usage

### Useful Commands

```bash
# View logs
docker-compose logs -f frontend

# Restart services
docker-compose restart

# Update deployment
./deploy.sh --clean

# Check resource usage
docker stats

# Access container shell
docker exec -it frontend_frontend_1 sh
```

## Production Monitoring

### Health Checks
- Endpoint: `/health`
- Expected response: "healthy"
- Check interval: 30 seconds

### Logs to Monitor
- Nginx access logs: `/var/log/nginx/access.log`
- Nginx error logs: `/var/log/nginx/error.log`
- Application logs: `docker-compose logs`

### Performance Metrics
- Response time
- Memory usage
- CPU usage
- Disk space
- Network traffic

## Security Considerations

- [ ] Regular security updates
- [ ] Monitor for vulnerabilities
- [ ] Review access logs
- [ ] Implement rate limiting (if needed)
- [ ] Regular backup verification

## Maintenance

### Regular Tasks
- [ ] Monitor application performance
- [ ] Review and rotate logs
- [ ] Update dependencies
- [ ] Security patches
- [ ] Backup verification

### Updates
- [ ] Test updates in staging environment
- [ ] Plan maintenance windows
- [ ] Prepare rollback procedures
- [ ] Notify users of maintenance
