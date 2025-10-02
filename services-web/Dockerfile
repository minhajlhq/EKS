# ---------- builder ----------
FROM python:3.12-slim AS builder
ENV PIP_NO_CACHE_DIR=1 PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /src
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --prefix /install

# ---------- runtime ----------
FROM python:3.12-slim
# Create non-root user and writable app dir
RUN useradd -m -u 10001 appuser && mkdir -p /app /app/tmp && chown -R appuser:appuser /app
WORKDIR /app
# Copy installed deps and app code
COPY --from=builder /install /usr/local
COPY app/ /app/
USER 10001
ENV PORT=8080 TMPDIR=/app/tmp PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
EXPOSE 8080
# Gunicorn serves the Flask app callable "app" from app.py
CMD ["gunicorn", "-w", "2", "-b", "0.0.0.0:8080", "app:app"]
