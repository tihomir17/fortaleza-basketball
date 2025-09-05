# apps/core/cache_utils.py

import hashlib
import json
import functools
from typing import Any, Callable, Optional, Dict, List
from django.core.cache import cache
from django.core.cache.utils import make_template_fragment_key
from django.conf import settings
import logging

logger = logging.getLogger(__name__)


class CacheManager:
    """Centralized cache management for the Basketball Analytics app"""
    
    # Cache timeouts (in seconds)
    CACHE_TIMEOUTS = {
        'analytics': 3600,      # 1 hour for analytics data
        'user_data': 1800,      # 30 minutes for user data
        'team_data': 1800,      # 30 minutes for team data
        'game_data': 900,       # 15 minutes for game data
        'dashboard': 300,       # 5 minutes for dashboard data
        'short_term': 60,       # 1 minute for frequently changing data
    }
    
    @staticmethod
    def generate_cache_key(prefix: str, *args, **kwargs) -> str:
        """Generate a consistent cache key from arguments"""
        # Convert all arguments to strings and sort for consistency
        key_parts = [str(arg) for arg in args]
        key_parts.extend([f"{k}={v}" for k, v in sorted(kwargs.items())])
        
        # Create a hash of the key parts
        key_string = ":".join(key_parts)
        key_hash = hashlib.md5(key_string.encode()).hexdigest()[:16]
        
        return f"{prefix}:{key_hash}"
    
    @staticmethod
    def get_or_set(
        key: str, 
        callable_func: Callable, 
        timeout: Optional[int] = None,
        cache_alias: str = 'default'
    ) -> Any:
        """Get from cache or set using callable function"""
        try:
            # Try to get from cache first
            cached_value = cache.get(key, using=cache_alias)
            if cached_value is not None:
                logger.debug(f"Cache hit for key: {key}")
                return cached_value
            
            # Cache miss - execute function and cache result
            logger.debug(f"Cache miss for key: {key}")
            result = callable_func()
            
            # Set cache with timeout
            cache_timeout = timeout or CacheManager.CACHE_TIMEOUTS.get('analytics', 3600)
            cache.set(key, result, timeout=cache_timeout, using=cache_alias)
            
            return result
            
        except Exception as e:
            logger.error(f"Cache error for key {key}: {e}")
            # Fallback to executing function without caching
            return callable_func()
    
    @staticmethod
    def invalidate_pattern(pattern: str, cache_alias: str = 'default') -> int:
        """Invalidate all cache keys matching a pattern"""
        try:
            # This is a simplified version - in production you'd use Redis SCAN
            # For now, we'll just log the pattern
            logger.info(f"Cache invalidation requested for pattern: {pattern}")
            return 0
        except Exception as e:
            logger.error(f"Cache invalidation error for pattern {pattern}: {e}")
            return 0
    
    @staticmethod
    def invalidate_user_cache(user_id: int) -> None:
        """Invalidate all cache entries for a specific user"""
        patterns = [
            f"user_data:{user_id}",
            f"dashboard:{user_id}",
            f"teams:user:{user_id}",
        ]
        
        for pattern in patterns:
            CacheManager.invalidate_pattern(pattern)
    
    @staticmethod
    def invalidate_team_cache(team_id: int) -> None:
        """Invalidate all cache entries for a specific team"""
        patterns = [
            f"team_data:{team_id}",
            f"games:team:{team_id}",
            f"analytics:team:{team_id}",
        ]
        
        for pattern in patterns:
            CacheManager.invalidate_pattern(pattern)


def cache_analytics_data(timeout: int = 3600):
    """Decorator for caching expensive analytics functions"""
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            # Generate cache key from function name and arguments
            cache_key = CacheManager.generate_cache_key(
                f"analytics:{func.__name__}", 
                *args, 
                **kwargs
            )
            
            return CacheManager.get_or_set(
                cache_key, 
                lambda: func(*args, **kwargs),
                timeout=timeout,
                cache_alias='analytics'
            )
        return wrapper
    return decorator


def cache_user_data(timeout: int = 1800):
    """Decorator for caching user-related data"""
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            cache_key = CacheManager.generate_cache_key(
                f"user_data:{func.__name__}", 
                *args, 
                **kwargs
            )
            
            return CacheManager.get_or_set(
                cache_key, 
                lambda: func(*args, **kwargs),
                timeout=timeout,
                cache_alias='default'
            )
        return wrapper
    return decorator


def cache_team_data(timeout: int = 1800):
    """Decorator for caching team-related data"""
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            cache_key = CacheManager.generate_cache_key(
                f"team_data:{func.__name__}", 
                *args, 
                **kwargs
            )
            
            return CacheManager.get_or_set(
                cache_key, 
                lambda: func(*args, **kwargs),
                timeout=timeout,
                cache_alias='default'
            )
        return wrapper
    return decorator


def cache_dashboard_data(timeout: int = 300):
    """Decorator for caching dashboard data"""
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            cache_key = CacheManager.generate_cache_key(
                f"dashboard:{func.__name__}", 
                *args, **kwargs
            )
            
            return CacheManager.get_or_set(
                cache_key, 
                lambda: func(*args, **kwargs),
                timeout=timeout,
                cache_alias='default'
            )
        return wrapper
    return decorator
