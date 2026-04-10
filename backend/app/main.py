"""FastAPI application factory."""

from __future__ import annotations

from typing import Any

from fastapi import FastAPI, HTTPException, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.routers import chores, devices, households, members, rewards, submissions


def _error_envelope(detail: Any) -> dict[str, Any]:
    """Normalize HTTPException detail into ``{code, detail}`` shape."""
    if isinstance(detail, dict) and "code" in detail and "detail" in detail:
        return detail
    return {"code": "error", "detail": str(detail)}


def create_app() -> FastAPI:
    """Build and return the FastAPI application."""
    app = FastAPI(
        title="ChoreChampion API",
        version="0.1.0",
        description="Backend for the ChoreChampion family chore-tracking app.",
    )

    # CORS: locked-down defaults. Flutter mobile doesn't care about CORS, but
    # the Swagger UI and any future admin web app do. Allow localhost by default.
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["http://localhost:3000", "http://localhost:5173"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Routers under /api/v1
    api_prefix = "/api/v1"
    app.include_router(households.router, prefix=api_prefix)
    app.include_router(devices.router, prefix=api_prefix)
    app.include_router(chores.router, prefix=api_prefix)
    app.include_router(submissions.router, prefix=api_prefix)
    app.include_router(rewards.router, prefix=api_prefix)
    app.include_router(members.router, prefix=api_prefix)

    @app.exception_handler(HTTPException)
    async def http_exc_handler(_req: Request, exc: HTTPException) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content=_error_envelope(exc.detail),
        )

    @app.exception_handler(RequestValidationError)
    async def validation_exc_handler(
        _req: Request, exc: RequestValidationError
    ) -> JSONResponse:
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content={
                "code": "validation_error",
                "detail": "Request validation failed",
                "errors": exc.errors(),
            },
        )

    @app.get("/healthz", tags=["health"])
    async def healthz() -> dict[str, str]:
        return {"status": "ok"}

    return app


app = create_app()
