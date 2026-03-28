"""
FastAPI Application — Modern REST API for EKS Deployment Demo
==============================================================
WHY FASTAPI OVER FLASK:
  - Auto-generates interactive API docs (Swagger UI at /docs)
  - Built-in data validation with Pydantic
  - Async support (handles more concurrent requests)
  - Type hints (better code quality)
  - Used heavily in AI/ML microservices (hot market skill!)

ENDPOINTS:
  /          → App info + pod metadata
  /health    → Liveness probe (is the app alive?)
  /ready     → Readiness probe (is it ready for traffic?)
  /info      → Detailed runtime info (debugging)
  /docs      → Auto-generated Swagger UI (interactive API docs!)
"""

import os
import socket
from datetime import datetime, timezone

from fastapi import FastAPI
from fastapi.responses import JSONResponse
from prometheus_fastapi_instrumentator import Instrumentator

# ---------- App Configuration ----------
APP_VERSION = os.getenv("APP_VERSION", "1.0.0")
ENVIRONMENT = os.getenv("ENVIRONMENT", "development")

app = FastAPI(
    title="EKS FastAPI Demo",
    description="A cloud-native microservice deployed on Kubernetes with Terraform & GitHub Actions",
    version=APP_VERSION,
    docs_url="/docs",      # Swagger UI — auto-generated!
    redoc_url="/redoc",    # Alternative docs UI
)

# ---------- Prometheus Metrics ----------
# Exposes /metrics endpoint with:
#   http_request_duration_seconds — latency histogram (p50/p90/p99)
#   http_request_duration_seconds_count — request counter (throughput)
#   http_requests_in_progress — current in-flight requests
Instrumentator().instrument(app).expose(app)


@app.get("/", tags=["Application"])
async def home():
    """
    Main endpoint — returns app info and Kubernetes pod metadata.
    
    In an interview, explain: "Each response shows the pod hostname,
    so when you refresh, you can see the Service load-balancing
    across different pods."
    """
    return {
        "app": "fastapi-eks-demo",
        "version": APP_VERSION,
        "environment": ENVIRONMENT,
        "hostname": socket.gethostname(),       # Shows Kubernetes pod name
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "message": "Hello from EKS! Deployed with Terraform + GitHub Actions",
        "docs": "Visit /docs for interactive API documentation"
    }


@app.get("/health", tags=["Health Checks"])
async def health():
    """
    Liveness probe endpoint for Kubernetes.
    
    Kubernetes checks this periodically.
    If it returns 200 → app is alive.
    If it fails → Kubernetes RESTARTS the pod.
    """
    return {"status": "healthy", "timestamp": datetime.now(timezone.utc).isoformat()}


@app.get("/ready", tags=["Health Checks"])
async def ready():
    """
    Readiness probe endpoint for Kubernetes.
    
    Returns 200 if the app is ready to receive traffic.
    If it fails → Kubernetes removes pod from Service (no traffic).
    Pod stays alive, just doesn't receive requests.
    
    In a real app, you'd check:
      - Database connection
      - Cache connection
      - External service dependencies
    """
    # Simulate real readiness checks
    checks = {
        "api": True,
        # "database": check_db_connection(),
        # "cache": check_redis_connection(),
    }
    
    all_ready = all(checks.values())
    status_code = 200 if all_ready else 503
    
    return JSONResponse(
        status_code=status_code,
        content={
            "status": "ready" if all_ready else "not_ready",
            "checks": checks,
            "timestamp": datetime.now(timezone.utc).isoformat()
        }
    )


@app.get("/info", tags=["Application"])
async def info():
    """
    Detailed runtime information — useful for debugging in Kubernetes.
    
    POD_IP, NODE_NAME, POD_NAMESPACE are injected by Kubernetes
    using the Downward API (fieldRef in deployment.yaml).
    """
    return {
        "app_version": APP_VERSION,
        "environment": ENVIRONMENT,
        "framework": "FastAPI",
        "hostname": socket.gethostname(),
        "pod_ip": os.getenv("POD_IP", "unknown"),
        "node_name": os.getenv("NODE_NAME", "unknown"),
        "namespace": os.getenv("POD_NAMESPACE", "unknown"),
        "timestamp": datetime.now(timezone.utc).isoformat()
    }


@app.get("/api/items/{item_id}", tags=["Sample API"])
async def get_item(item_id: int, q: str = None):
    """
    Sample API endpoint demonstrating FastAPI features:
      - Path parameters with type validation (item_id must be int)
      - Optional query parameters
      - Auto-generated in Swagger docs
    
    Try it: /api/items/42?q=hello
    Try it: /api/items/abc → automatic 422 error (not an integer!)
    """
    result = {"item_id": item_id, "served_by": socket.gethostname()}
    if q:
        result["query"] = q
    return result
