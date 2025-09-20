FROM python:3.11-alpine

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY . .

# Create non-root user
RUN adduser -D -s /bin/sh iotuser && \
    chown -R iotuser:iotuser /app
USER iotuser

EXPOSE 8080

CMD ["python", "app.py"]