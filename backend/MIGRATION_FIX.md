# 🔧 Migration Fix - Django Dependency Issue

## ❌ **Error Message**
```
ValueError: Dependency on app with no migrations: users
IndexError: list index out of range
```

## 🔍 **Root Cause**

This error occurs when:
1. **Migration dependencies are broken** - One app references another app that Django can't find
2. **Database migration state is inconsistent** - The database has migration records that don't match the current code
3. **App configuration issues** - Django can't properly load the `users` app

## ✅ **Solutions**

### **Option 1: Fix Migrations (Recommended)**
```bash
# Run the migration fix script
./fix-migrations.sh
```

This script will:
- Check current migration status
- Fake apply problematic migrations
- Run all migrations properly
- Test superuser creation

### **Option 2: Reset Migrations (Nuclear Option)**
```bash
# Complete migration reset (WARNING: This will delete all data)
./reset-migrations.sh
```

This script will:
- Drop and recreate the database
- Run migrations from scratch
- Create a superuser

### **Option 3: Manual Fix**
```bash
# Check migration status
docker-compose -f docker-compose.production.yml exec web python manage.py showmigrations

# Fake apply initial migrations
docker-compose -f docker-compose.production.yml exec web python manage.py migrate users 0001 --fake

# Run all migrations
docker-compose -f docker-compose.production.yml exec web python manage.py migrate

# Test superuser creation
docker-compose -f docker-compose.production.yml exec web python manage.py createsuperuser
```

## 🧪 **Verification**

### Check Migration Status
```bash
# View all migrations
docker-compose -f docker-compose.production.yml exec web python manage.py showmigrations

# Check for unapplied migrations
docker-compose -f docker-compose.production.yml exec web python manage.py showmigrations --plan
```

### Test Database
```bash
# Test database connection
docker-compose -f docker-compose.production.yml exec web python manage.py check --database default

# Test user model
docker-compose -f docker-compose.production.yml exec web python manage.py shell -c "from django.contrib.auth import get_user_model; User = get_user_model(); print('✅ User model accessible')"
```

## 🔍 **Common Migration Issues**

### 1. **Missing Migration Files**
```
ValueError: Dependency on app with no migrations: users
```
**Solution**: Ensure all apps have proper migration files in their `migrations/` directory

### 2. **Circular Dependencies**
```
ValueError: Circular dependency detected
```
**Solution**: Review migration dependencies and remove circular references

### 3. **Database State Mismatch**
```
IndexError: list index out of range
```
**Solution**: Reset migration state or fake apply migrations

### 4. **App Not in INSTALLED_APPS**
```
ValueError: App 'users' not found
```
**Solution**: Ensure app is properly configured in `INSTALLED_APPS`

## 🛠️ **Prevention**

### Best Practices
1. **Always run migrations** after code changes
2. **Test migrations** in development before production
3. **Backup database** before major migration changes
4. **Use version control** for migration files
5. **Avoid manual database changes** that bypass migrations

### Migration Workflow
```bash
# 1. Make model changes
# 2. Create migrations
python manage.py makemigrations

# 3. Review migrations
python manage.py showmigrations

# 4. Apply migrations
python manage.py migrate

# 5. Test application
python manage.py check
```

## 🚨 **Emergency Recovery**

If all else fails:

### Complete Reset
```bash
# Stop services
docker-compose -f docker-compose.production.yml down

# Remove database volume
docker volume rm fortaleza-basketball-analytics_postgres_data

# Start services (will recreate database)
docker-compose -f docker-compose.production.yml up -d

# Run migrations
docker-compose -f docker-compose.production.yml exec web python manage.py migrate

# Create superuser
docker-compose -f docker-compose.production.yml exec web python manage.py createsuperuser
```

## 📋 **Troubleshooting Checklist**

- [ ] ✅ Checked migration status
- [ ] ✅ Verified app configuration
- [ ] ✅ Fixed migration dependencies
- [ ] ✅ Applied all migrations
- [ ] ✅ Tested database connection
- [ ] ✅ Verified user model accessibility
- [ ] ✅ Successfully created superuser

## 🎯 **Expected Result**

After fixing migrations:
- ✅ All migrations are applied
- ✅ Database schema is correct
- ✅ User model is accessible
- ✅ Superuser creation works
- ✅ Application starts properly

---

**The migration dependency issue should now be resolved!** 🎉
