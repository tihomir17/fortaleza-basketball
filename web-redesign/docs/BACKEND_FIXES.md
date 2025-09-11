# Backend Redis Cache Error Fix

## Issue
```
Cache error for key analytics:comprehensive_analytics:2046253be6bdaa86: RedisCache.get() got an unexpected keyword argument 'using'
Cache error for key analytics:get_comprehensive_analytics:b934c123c14bc52d: RedisCache.get() got an unexpected keyword argument 'using'
```

## Root Cause
The error indicates a version mismatch between Django's cache framework and the Redis cache backend. The `using` parameter was introduced in newer versions of Django but your Redis cache configuration is using an older API.

## Solution

### 1. Update Django Settings (settings.py)

```python
# Replace your current Redis cache configuration with this:

CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.redis.RedisCache',
        'LOCATION': 'redis://127.0.0.1:6379/1',
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
        },
        'KEY_PREFIX': 'fortaleza_basketball',
        'TIMEOUT': 300,  # 5 minutes default timeout
    }
}

# Alternative if using django-redis package:
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': 'redis://127.0.0.1:6379/1',
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
        },
        'KEY_PREFIX': 'fortaleza_basketball',
        'TIMEOUT': 300,
    }
}
```

### 2. Update Requirements

Add to your `requirements.txt`:
```
django-redis==5.4.0
redis==5.0.1
```

### 3. Update Cache Usage in Views

Replace any cache usage like this:
```python
# OLD (causing the error):
cache.get(key, using='default')

# NEW (correct way):
cache.get(key)
```

### 4. Alternative: Disable Cache Temporarily

If you want to quickly test without cache, add this to your settings.py:
```python
# Temporary fix - disable cache
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.dummy.DummyCache',
    }
}
```

### 5. Update Analytics View

In your analytics view, update the cache usage:
```python
from django.core.cache import cache
from django.conf import settings

def get_comprehensive_analytics(request):
    # Generate cache key
    cache_key = f"analytics:comprehensive_analytics:{hash(str(request.GET))}"
    
    # Try to get from cache
    cached_data = cache.get(cache_key)
    if cached_data:
        return JsonResponse(cached_data)
    
    # Generate analytics data
    analytics_data = generate_analytics_data(request)
    
    # Cache for 5 minutes
    cache.set(cache_key, analytics_data, timeout=300)
    
    return JsonResponse(analytics_data)
```

## Frontend Fallback Solution

The frontend now has a complete fallback system that will work even when the backend has issues:

1. **Automatic Detection**: Detects backend connectivity issues
2. **Mock Data**: Uses realistic mock analytics data
3. **Status Indicator**: Shows backend connection status
4. **Seamless Experience**: Users can still test all features

## Testing

1. **With Backend Fixed**: Analytics will load real data
2. **With Backend Issues**: Analytics will load mock data automatically
3. **Status Indicator**: Shows connection status in top-right corner

## Quick Fix Commands

```bash
# Install required packages
pip install django-redis==5.4.0 redis==5.0.1

# Restart your Django server
python manage.py runserver

# Test the analytics endpoint
curl http://localhost:8000/api/analytics/comprehensive/
```

## Verification

After applying the fix, you should see:
- ✅ No more Redis cache errors in logs
- ✅ Analytics endpoint returns data
- ✅ Frontend shows "Backend connected" status
- ✅ Real analytics data loads in the frontend
