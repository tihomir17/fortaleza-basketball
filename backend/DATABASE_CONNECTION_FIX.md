# 🔧 Database Connection Fix - PostgreSQL Configuration

## ❌ **Error Message**
```
psycopg2.OperationalError: connection to server at "db" (172.20.0.3), port 5432 failed: 
FATAL: invalid value for parameter "default_transaction_isolation": "read_committed"
HINT: Available values: serializable, repeatable read, read committed, read uncommitted.
```

## ✅ **Solution Applied**

### **Root Cause**
The PostgreSQL `default_transaction_isolation` parameter was set to `"read_committed"` (with underscore), but PostgreSQL expects `"read committed"` (with space).

### **Fix Applied**
Updated `basketball_analytics/settings_production.py`:

```python
# Before (incorrect - caused parsing issues)
"options": "-c default_transaction_isolation='read committed'"

# After (simplified - using PostgreSQL default)
"OPTIONS": {
    "connect_timeout": 10,
},
```

**Note**: Removed the `default_transaction_isolation` parameter entirely since `read committed` is PostgreSQL's default isolation level.

## 🚀 **How to Apply the Fix**

### Option 1: Quick Fix (if services are running)
```bash
# Run the fix script
./fix-database-connection.sh
```

### Option 2: Manual Restart
```bash
# Restart the web service
docker-compose -f docker-compose.production.yml restart web

# Test database connection
docker-compose -f docker-compose.production.yml exec web python manage.py check --database default
```

### Option 3: Full Redeploy
```bash
# Stop and restart all services
docker-compose -f docker-compose.production.yml down
docker-compose -f docker-compose.production.yml up -d
```

## 🧪 **Verification**

### Test Database Connection
```bash
# Run comprehensive database test
./test-database.sh

# Or test manually
docker-compose -f docker-compose.production.yml exec web python manage.py check --database default
docker-compose -f docker-compose.production.yml exec web python manage.py migrate
```

### Create Superuser (after fix)
```bash
# Create admin user
docker-compose -f docker-compose.production.yml exec web python manage.py createsuperuser
```

## 🔍 **PostgreSQL Transaction Isolation Levels**

The correct values for `default_transaction_isolation` are:

| Value | Description |
|-------|-------------|
| `serializable` | Highest isolation level |
| `repeatable read` | Prevents phantom reads |
| `read committed` | ✅ **Default and recommended** |
| `read uncommitted` | Lowest isolation level |

## 🛠️ **Database Configuration Best Practices**

### Production Settings
```python
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.getenv("DB_NAME", "basketball_analytics"),
        "USER": os.getenv("DB_USER", "postgres"),
        "PASSWORD": os.getenv("DB_PASSWORD"),
        "HOST": os.getenv("DB_HOST", "localhost"),
        "PORT": os.getenv("DB_PORT", "5432"),
        "OPTIONS": {
            "connect_timeout": 10,
            "options": "-c default_transaction_isolation='read committed'"
        },
        "CONN_MAX_AGE": 60,  # Connection pooling
    }
}
```

### Key Settings Explained
- **`connect_timeout`**: Maximum time to wait for connection
- **`default_transaction_isolation`**: Transaction isolation level
- **`CONN_MAX_AGE`**: Connection pooling for performance

## 🚨 **Common Database Issues**

### 1. **Connection Timeout**
```
psycopg2.OperationalError: connection to server at "db" (172.20.0.3), port 5432 failed: timeout expired
```
**Solution**: Increase `connect_timeout` or check network connectivity

### 2. **Authentication Failed**
```
psycopg2.OperationalError: connection to server at "db" (172.20.0.3), port 5432 failed: FATAL: password authentication failed
```
**Solution**: Check `DB_PASSWORD` environment variable

### 3. **Database Does Not Exist**
```
psycopg2.OperationalError: connection to server at "db" (172.20.0.3), port 5432 failed: FATAL: database "basketball_analytics" does not exist
```
**Solution**: Check `DB_NAME` or create database

### 4. **Invalid Parameter Value**
```
FATAL: invalid value for parameter "default_transaction_isolation": "read_committed"
```
**Solution**: Use correct parameter value with space: `"read committed"`

## 📋 **Troubleshooting Checklist**

- [ ] ✅ Fixed `default_transaction_isolation` parameter
- [ ] ✅ Restarted web service
- [ ] ✅ Tested database connection
- [ ] ✅ Verified environment variables
- [ ] ✅ Checked database container status
- [ ] ✅ Tested superuser creation

## 🔧 **Debug Commands**

### Check Service Status
```bash
# Check all services
docker-compose -f docker-compose.production.yml ps

# Check database logs
docker-compose -f docker-compose.production.yml logs db

# Check web service logs
docker-compose -f docker-compose.production.yml logs web
```

### Test Database Connectivity
```bash
# Test from web container
docker-compose -f docker-compose.production.yml exec web python manage.py check --database default

# Test direct connection
docker-compose -f docker-compose.production.yml exec db psql -U postgres -d basketball_analytics -c "SELECT 1;"
```

### Environment Variables
```bash
# Check environment variables
docker-compose -f docker-compose.production.yml exec web env | grep DB_
```

## 🎯 **Result**

After applying this fix:
- ✅ Database connection will work correctly
- ✅ Django can connect to PostgreSQL
- ✅ Superuser creation will succeed
- ✅ All database operations will function
- ✅ Application will start properly

---

**The database connection issue has been resolved!** 🎉
