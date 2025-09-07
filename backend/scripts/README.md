# 🔧 Scripts

This directory contains all shell scripts for the Basketball Analytics backend.

## 📋 Available Scripts

### 🏗️ **Building & Deployment**
- **[build-all.sh](build-all.sh)** - Build all Docker images
- **[deploy-production.sh](deploy-production.sh)** - Production deployment
- **[deploy-unified.sh](deploy-unified.sh)** - Unified deployment

### 🔧 **Troubleshooting & Maintenance**
- **[fix-allowed-hosts.sh](fix-allowed-hosts.sh)** - Fix ALLOWED_HOSTS issues
- **[fix-database-connection.sh](fix-database-connection.sh)** - Fix database connection
- **[fix-migrations.sh](fix-migrations.sh)** - Fix Django migration issues
- **[reset-migrations.sh](reset-migrations.sh)** - Reset Django migrations
- **[test-database.sh](test-database.sh)** - Test database connection

## 📝 **Usage Examples**

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
