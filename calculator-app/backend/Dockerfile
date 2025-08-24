FROM python:3.13.7-slim

# Set environment variables for Python and MySQL
ENV PYTHONDONTWRITEBYTECODE=1 \
  PYTHONUNBUFFERED=1 \
  MYSQL_HOST=localhost \
  MYSQL_DB=calculator_db \
  MYSQL_USER=calculator_user \
  MYSQL_PASSWORD=

WORKDIR /app

# Install system dependencies and clean up
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
    build-essential \
    pkg-config \
    libffi-dev \
    default-libmysqlclient-dev \
    libssl-dev \
  && apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --upgrade pip && \
  pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Use a non-root user for security
RUN useradd --create-home appuser
USER appuser

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=5s CMD wget -q --spider http://localhost:5000 || exit 1

# Use exec form for ENTRYPOINT and CMD
ENTRYPOINT ["gunicorn"]
CMD ["--bind=0.0.0.0:5000", "app:app", "--workers=2", "--threads=4", "--timeout=60"]
