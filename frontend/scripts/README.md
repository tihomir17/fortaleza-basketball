# Frontend Scripts

This directory contains all shell scripts for the Flutter frontend application.

## Scripts

### 🚀 Main Script (Recommended)
- **`build-and-push.sh`** - **Complete build and push script** - Handles authentication, multi-architecture building, and pushing

### Deployment Scripts
- **`deploy.sh`** - Basic deployment script
- **`deploy-mobile-fix.sh`** - Deploy mobile-compatible frontend
- **`deploy-multiarch.sh`** - Deploy multi-architecture Docker image (AMD64 + ARM64)

### Build Scripts
- **`build.sh`** - Build Flutter web application

## Usage

### 🚀 Complete Build and Push (Recommended)
```bash
./scripts/build-and-push.sh
```
This script handles everything:
- Google Cloud authentication
- Docker configuration
- Multi-architecture building (AMD64 + ARM64)
- Pushing to Artifact Registry
- Verification and deployment instructions

### Deploy Mobile-Friendly Frontend
```bash
./scripts/deploy-mobile-fix.sh
```

### Deploy Multi-Architecture Image
```bash
./scripts/deploy-multiarch.sh
```

### Build Flutter App
```bash
./scripts/build.sh
```

## Docker Images

All scripts push to Google Cloud Artifact Registry:
- Repository: `us-central1-docker.pkg.dev/inat-drive/inatdrive/frontend`
- Tag: `latest`

## Prerequisites

- Docker installed and running
- Google Cloud CLI authenticated (`gcloud auth login`)
- Docker configured for Artifact Registry (`gcloud auth configure-docker us-central1-docker.pkg.dev`)
