# Dockerfile for Hugging Face Spaces or other cloud deployments
FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python packages
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY server_birefnet.py .

# Create a non-root user
RUN useradd -m -u 1000 user && chown -R user:user /app
USER user

# Expose port (7860 for Hugging Face Spaces, 8000 for general use)
EXPOSE 7860

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:7860/health')" || exit 1

# Run the application
CMD ["uvicorn", "server_birefnet:app", "--host", "0.0.0.0", "--port", "7860"]