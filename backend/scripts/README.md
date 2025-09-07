# 🔧 Scripts

This directory contains all shell scripts for the Basketball Analytics backend.

## 📋 Available Scripts

### 🏗️ **Building & Deployment**
- **[build-all.sh](build-all.sh)** - Build all Docker images
- **[deploy-production.sh](deploy-production.sh)** - Production deployment
- **[deploy-unified.sh](deploy-unified.sh)** - Unified deployment
- **[deploy-all.sh](deploy-all.sh)** - Complete deployment (backend + frontend + database)
- **[deploy-current-changes.sh](deploy-current-changes.sh)** - Deploy current changes only
- **[deploy-clean-production.sh](deploy-clean-production.sh)** - Clean production deployment (NO source code on server)

### 🗄️ **Database Management**
- **[populate-production-database.sh](populate-production-database.sh)** - Populate production database with realistic data
- **[populate-playsets-only.sh](populate-playsets-only.sh)** - Populate only play definitions (playsets)

### 🔧 **Troubleshooting & Maintenance**
- **[fix-allowed-hosts.sh](fix-allowed-hosts.sh)** - Fix ALLOWED_HOSTS issues
- **[fix-database-connection.sh](fix-database-connection.sh)** - Fix database connection
- **[fix-migrations.sh](fix-migrations.sh)** - Fix Django migration issues
- **[reset-migrations.sh](reset-migrations.sh)** - Reset Django migrations
- **[test-database.sh](test-database.sh)** - Test database connection

## 📝 **Usage Examples**

### **Clean Production Deployment (Recommended)**
```bash
cd backend
# Deploy with NO source code on production server
./scripts/deploy-clean-production.sh
```

### **Complete Deployment**
```bash
cd backend
# Deploy everything: backend + frontend + database population
./scripts/deploy-all.sh
```

### **Quick Deployment (Current Changes Only)**
```bash
cd backend
# Deploy only current changes without full rebuild
./scripts/deploy-current-changes.sh
```

### **Production Deployment**
```bash
cd backend
./scripts/deploy-production.sh
```

### **Troubleshooting**
```bash
cd backend
./scripts/fix-database-connection.sh
./scripts/test-database.sh
```

### **Database Population**
```bash
cd backend
# Populate only play definitions (playsets)
./scripts/populate-playsets-only.sh

# Or populate complete database with realistic data
./scripts/populate-production-database.sh
```

### **Building**
```bash
cd backend
./scripts/build-all.sh
```

## 📞 **Support**

If you encounter issues:
1. Check the troubleshooting scripts above
2. Review the documentation in the `docs/` folder
3. Check the main README.md in the project root

---

**All scripts are organized and ready to help you get started!** 🔧🏀
