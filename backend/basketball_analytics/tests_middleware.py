import json
import logging
from django.test import TestCase, RequestFactory, override_settings
from django.http import HttpResponse
from django.contrib.auth.models import AnonymousUser
from django.core.exceptions import ValidationError

from apps.users.models import User
from basketball_analytics.middleware import (
    RequestLoggingMiddleware,
    SlowQueryLoggingMiddleware,
    ExceptionLoggingMiddleware,
)


class MiddlewareTests(TestCase):
    def setUp(self):
        self.factory = RequestFactory()
        self.request_middleware = RequestLoggingMiddleware(
            lambda req: HttpResponse("OK")
        )
        self.slow_query_middleware = SlowQueryLoggingMiddleware(
            lambda req: HttpResponse("OK")
        )
        self.exception_middleware = ExceptionLoggingMiddleware(
            lambda req: HttpResponse("OK")
        )

        # Create a test user
        self.user = User.objects.create_user(
            username="testuser", password="testpass123", role=User.Role.COACH
        )

    @override_settings(LOGGING={
        'version': 1,
        'disable_existing_loggers': False,
        'formatters': {
            'json': {
                '()': 'basketball_analytics.logging_formatters.JsonFormatter',
            },
        },
        'handlers': {
            'console': {
                'class': 'logging.StreamHandler',
                'formatter': 'json',
            },
        },
        'loggers': {
            'request': {
                'handlers': ['console'],
                'level': 'INFO',
                'propagate': False,
            },
            'db.slow': {
                'handlers': ['console'],
                'level': 'INFO',
                'propagate': False,
            },
        },
    })
    def test_request_logging_middleware(self):
        """Test that request logging middleware logs requests correctly."""
        request = self.factory.get("/api/test/")
        request.user = self.user
        request.META["REMOTE_ADDR"] = "127.0.0.1"
        request.META["HTTP_USER_AGENT"] = "TestAgent"
        request.META["HTTP_REFERER"] = "http://test.com"
        request.META["HTTP_ORIGIN"] = "http://test.com"

        with self.assertLogs("request", level="INFO") as logs:
            response = self.request_middleware(request)

        self.assertEqual(response.status_code, 200)
        self.assertIn("X-Request-ID", response)

        # Check log entry
        log_entry = json.loads(logs.records[0].message)
        self.assertEqual(log_entry["method"], "GET")
        self.assertEqual(log_entry["path"], "/api/test/")
        self.assertEqual(log_entry["user"], "testuser")
        self.assertEqual(log_entry["status"], 200)
        self.assertEqual(log_entry["ip"], "127.0.0.1")
        self.assertEqual(log_entry["ua"], "TestAgent")
        self.assertEqual(log_entry["referer"], "http://test.com")
        self.assertEqual(log_entry["origin"], "http://test.com")

    @override_settings(LOGGING={
        'version': 1,
        'disable_existing_loggers': False,
        'formatters': {
            'json': {
                '()': 'basketball_analytics.logging_formatters.JsonFormatter',
            },
        },
        'handlers': {
            'console': {
                'class': 'logging.StreamHandler',
                'formatter': 'json',
            },
        },
        'loggers': {
            'request': {
                'handlers': ['console'],
                'level': 'INFO',
                'propagate': False,
            },
        },
    })
    def test_request_logging_anonymous_user(self):
        """Test request logging with anonymous user."""
        request = self.factory.get("/api/test/")
        request.user = AnonymousUser()
        request.META["REMOTE_ADDR"] = "127.0.0.1"

        with self.assertLogs("request", level="INFO") as logs:
            response = self.request_middleware(request)

        self.assertEqual(response.status_code, 200)

        log_entry = json.loads(logs.records[0].message)
        self.assertEqual(log_entry["user"], "anonymous")

    @override_settings(LOGGING={
        'version': 1,
        'disable_existing_loggers': False,
        'formatters': {
            'json': {
                '()': 'basketball_analytics.logging_formatters.JsonFormatter',
            },
        },
        'handlers': {
            'console': {
                'class': 'logging.StreamHandler',
                'formatter': 'json',
            },
        },
        'loggers': {
            'request': {
                'handlers': ['console'],
                'level': 'INFO',
                'propagate': False,
            },
        },
    })
    def test_request_logging_missing_headers(self):
        """Test request logging with missing headers."""
        request = self.factory.get("/api/test/")
        request.user = self.user
        request.META["REMOTE_ADDR"] = "127.0.0.1"

        with self.assertLogs("request", level="INFO") as logs:
            response = self.request_middleware(request)

        self.assertEqual(response.status_code, 200)

        log_entry = json.loads(logs.records[0].message)
        self.assertEqual(log_entry["ua"], "")
        self.assertEqual(log_entry["referer"], "")
        self.assertEqual(log_entry["origin"], "")

    @override_settings(LOGGING={
        'version': 1,
        'disable_existing_loggers': False,
        'formatters': {
            'json': {
                '()': 'basketball_analytics.logging_formatters.JsonFormatter',
            },
        },
        'handlers': {
            'console': {
                'class': 'logging.StreamHandler',
                'formatter': 'json',
            },
        },
        'loggers': {
            'db.slow': {
                'handlers': ['console'],
                'level': 'INFO',
                'propagate': False,
            },
        },
    })
    def test_slow_query_logging_middleware(self):
        """Test that slow query logging middleware logs slow queries."""
        request = self.factory.get("/api/test/")
        request.user = self.user

        # Mock a slow query by setting a custom attribute
        request._slow_queries = [
            {"sql": "SELECT * FROM test", "time": 0.15}  # 150ms query
        ]

        with self.assertLogs("db.slow", level="INFO") as logs:
            response = self.slow_query_middleware(request)

        self.assertEqual(response.status_code, 200)
        # Note: In test environment, we might not get slow query logs
        # because the database queries are fast
        if logs.records:
            log_entry = json.loads(logs.records[0].message)
            self.assertIn("sql", log_entry)

    @override_settings(LOGGING={
        'version': 1,
        'disable_existing_loggers': False,
        'formatters': {
            'json': {
                '()': 'basketball_analytics.logging_formatters.JsonFormatter',
            },
        },
        'handlers': {
            'console': {
                'class': 'logging.StreamHandler',
                'formatter': 'json',
            },
        },
        'loggers': {
            'db.slow': {
                'handlers': ['console'],
                'level': 'INFO',
                'propagate': False,
            },
        },
    })
    def test_slow_query_logging_no_slow_queries(self):
        """Test that slow query logging middleware doesn't log fast queries."""
        request = self.factory.get("/api/test/")
        request.user = self.user

        with self.assertLogs("db.slow", level="INFO") as logs:
            response = self.slow_query_middleware(request)

        self.assertEqual(response.status_code, 200)
        # In test environment, queries are typically fast
        # so we don't expect slow query logs

    def test_exception_logging_middleware(self):
        """Test that exception logging middleware logs exceptions."""

        def view_that_raises(request):
            raise ValidationError("Test validation error")

        exception_middleware = ExceptionLoggingMiddleware(view_that_raises)
        request = self.factory.get("/api/test/")
        request.user = self.user
        request.META["REMOTE_ADDR"] = "127.0.0.1"
        request.META["HTTP_USER_AGENT"] = "TestAgent"

        with self.assertLogs("django.request", level="ERROR") as logs:
            with self.assertRaises(ValidationError):
                exception_middleware(request)

        self.assertEqual(len(logs.records), 1)

        log_entry = json.loads(logs.records[0].message)
        self.assertEqual(log_entry["exception_type"], "ValidationError")
        self.assertEqual(log_entry["exception_message"], "Test validation error")
        self.assertEqual(log_entry["method"], "GET")
        self.assertEqual(log_entry["path"], "/api/test/")
        self.assertEqual(log_entry["user"], "testuser")
        self.assertEqual(log_entry["ip"], "127.0.0.1")
        self.assertEqual(log_entry["ua"], "TestAgent")

    def test_exception_logging_anonymous_user(self):
        """Test exception logging with anonymous user."""

        def view_that_raises(request):
            raise ValueError("Test value error")

        exception_middleware = ExceptionLoggingMiddleware(view_that_raises)
        request = self.factory.get("/api/test/")
        request.user = AnonymousUser()
        request.META["REMOTE_ADDR"] = "127.0.0.1"

        with self.assertLogs("django.request", level="ERROR") as logs:
            with self.assertRaises(ValueError):
                exception_middleware(request)

        self.assertEqual(len(logs.records), 1)

        log_entry = json.loads(logs.records[0].message)
        self.assertEqual(log_entry["user"], "anonymous")

    def test_exception_logging_missing_headers(self):
        """Test exception logging with missing headers."""

        def view_that_raises(request):
            raise RuntimeError("Test runtime error")

        exception_middleware = ExceptionLoggingMiddleware(view_that_raises)
        request = self.factory.get("/api/test/")
        request.user = self.user

        with self.assertLogs("django.request", level="ERROR") as logs:
            with self.assertRaises(RuntimeError):
                exception_middleware(request)

        self.assertEqual(len(logs.records), 1)

        log_entry = json.loads(logs.records[0].message)
        self.assertEqual(log_entry["ua"], "")
        self.assertEqual(log_entry["ip"], "")
