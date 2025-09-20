#!/usr/bin/env python3
"""
ServicePi IoT API Service - Simplified for testing
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
from datetime import datetime
import urllib.parse

class Handler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # Suppress default request logging
        pass
    
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        
        if self.path == "/health":
            response = {
                "status": "healthy", 
                "service": "ServicePi IoT", 
                "timestamp": datetime.utcnow().isoformat()
            }
        elif self.path == "/api/sensors":
            response = {
                "sensors": {
                    "temperature_sensor": {"status": "online", "last_reading": 22.5, "unit": "°C"},
                    "humidity_sensor": {"status": "online", "last_reading": 65.2, "unit": "%"}
                }, 
                "timestamp": datetime.utcnow().isoformat()
            }
        elif self.path.startswith("/api/"):
            response = {
                "status": "ok", 
                "endpoint": self.path,
                "timestamp": datetime.utcnow().isoformat()
            }
        else:
            response = {
                "service": "ServicePi IoT", 
                "version": "1.0.0", 
                "timestamp": datetime.utcnow().isoformat(),
                "endpoints": ["/health", "/api/sensors", "/api/system/communicate"]
            }
        
        self.wfile.write(json.dumps(response, indent=2).encode())

    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        if content_length > 0:
            post_data = self.rfile.read(content_length)
        
        self.send_response(200)
        self.send_header("Content-type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        
        response = {
            "status": "communication_ok", 
            "method": "POST",
            "endpoint": self.path,
            "timestamp": datetime.utcnow().isoformat()
        }
        
        self.wfile.write(json.dumps(response, indent=2).encode())

if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", 8080), Handler)
    print("ServicePi IoT service starting on port 8080")
    server.serve_forever()