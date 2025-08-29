import time
import logging
import uuid
from typing import Callable
from django.http import HttpRequest, HttpResponse
from django.conf import settings
from django.db import connection

request_logger = logging.getLogger("request")
slow_logger = logging.getLogger("db.slow")
error_logger = logging.getLogger("django.request")


class RequestLoggingMiddleware:
    def __init__(self, get_response: Callable[[HttpRequest], HttpResponse]):
        self.get_response = get_response

    def __call__(self, request: HttpRequest) -> HttpResponse:
        start = time.perf_counter()
        request_id = request.headers.get("X-Request-ID") or str(uuid.uuid4())
        response = None
        try:
            response = self.get_response(request)
            return response
        finally:
            duration_ms = int((time.perf_counter() - start) * 1000)
            user_repr = getattr(request, "user", None)
            user_str = (
                getattr(user_repr, "username", "anonymous")
                if user_repr
                else "anonymous"
            )
            status_code = getattr(response, "status_code", 0) if response else 0
            ip = request.META.get("HTTP_X_FORWARDED_FOR") or request.META.get(
                "REMOTE_ADDR"
            )
            ua = request.META.get("HTTP_USER_AGENT", "")
            referer = request.META.get("HTTP_REFERER", "")
            origin = request.META.get("HTTP_ORIGIN", "")
            extra = {
                "method": request.method,
                "path": request.get_full_path(),
                "user": user_str,
                "status": status_code,
                "duration_ms": duration_ms,
                "ip": ip,
                "ua": ua,
                "referer": referer,
                "origin": origin,
                "request_id": request_id,
            }
            if response is not None:
                response["X-Request-ID"] = request_id
            request_logger.info("request completed", extra=extra)


class SlowQueryLoggingMiddleware:
    def __init__(self, get_response: Callable[[HttpRequest], HttpResponse]):
        self.get_response = get_response

    def __call__(self, request: HttpRequest) -> HttpResponse:
        threshold_ms = getattr(settings, "SLOW_QUERY_MS", 200)
        start_count = len(connection.queries)
        start_time = time.perf_counter()
        response = self.get_response(request)
        total_time = (time.perf_counter() - start_time) * 1000
        for q in connection.queries[start_count:]:
            try:
                duration = float(q.get("time", 0)) * 1000  # seconds -> ms
            except Exception:
                duration = 0
            if duration >= threshold_ms:
                slow_logger.info(
                    "slow query",
                    extra={
                        "duration_ms": int(duration),
                        "sql": q.get("sql", ""),
                        "params": q.get("params", ""),
                    },
                )
        return response


class ExceptionLoggingMiddleware:
    def __init__(self, get_response: Callable[[HttpRequest], HttpResponse]):
        self.get_response = get_response

    def __call__(self, request: HttpRequest) -> HttpResponse:
        try:
            return self.get_response(request)
        except Exception as exc:
            ip = request.META.get("HTTP_X_FORWARDED_FOR") or request.META.get(
                "REMOTE_ADDR"
            )
            ua = request.META.get("HTTP_USER_AGENT", "")
            error_logger.exception(
                "unhandled exception",
                extra={
                    "method": request.method,
                    "path": request.get_full_path(),
                    "ip": ip,
                    "ua": ua,
                },
            )
            raise
