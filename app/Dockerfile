# ============================================================================
# DOCKERFILE — Multi-stage build for FastAPI app
# ============================================================================
# WHY FASTAPI + UVICORN:
#   Flask uses gunicorn (WSGI — synchronous, older)
#   FastAPI uses uvicorn (ASGI — async, modern, faster)
#
# SECURITY BEST PRACTICES:
#   - Multi-stage build (small image ~60MB)
#   - Non-root user
#   - Read-only filesystem compatible
#   - No unnecessary packages
# ============================================================================

# ---------- Stage 1: Builder ----------
FROM python:3.12-slim AS builder

WORKDIR /build

COPY requirements.txt .
RUN python -m venv /opt/venv && \
    /opt/venv/bin/pip install --no-cache-dir --upgrade pip && \
    /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

# ---------- Stage 2: Production ----------
FROM python:3.12-slim

# Security: Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser -d /app -s /sbin/nologin appuser

WORKDIR /app

# Copy virtual env from builder
COPY --from=builder /opt/venv /opt/venv

# Copy application code
COPY main.py .

# Use the virtual env
ENV PATH="/opt/venv/bin:$PATH"
ENV PYTHONUNBUFFERED=1
ENV PORT=8000

# Switch to non-root user
USER appuser

EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

# Run with uvicorn (ASGI server — async, production-ready)
# --host 0.0.0.0 = listen on all interfaces (required for containers)
# --workers 3 = multiple worker processes for handling concurrent requests
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]
