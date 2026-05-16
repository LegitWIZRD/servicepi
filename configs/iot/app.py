#!/usr/bin/env python3
"""
ServicePi IoT API Service
Provides REST API for IoT device management and sensor data
"""

import os
import json
import secrets
import configparser
import concurrent.futures
from datetime import datetime
from flask import Flask, jsonify, request
from flask_wtf.csrf import CSRFProtect
from flask_cors import CORS
import requests
import traceback
app = Flask(__name__)

# Configure CSRF protection
# Use a secret key from environment or generate a random one
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', os.urandom(32).hex())
# Disable CSRF for API endpoints since they're accessed via proxy and may use tokens
app.config['WTF_CSRF_ENABLED'] = False  # Will be enabled selectively
app.config['WTF_CSRF_CHECK_DEFAULT'] = False

csrf = CSRFProtect(app)

# Configure CORS to allow requests from the web dashboard and other services.
# Browser requests from the dashboard are proxied through Nginx (same-origin),
# so CORS is not required for normal dashboard use.  The wildcard default
# ensures direct API access (e.g. curl, automation tools, or other services)
# works without additional configuration.  Set the CORS_ORIGINS environment
# variable to a comma-separated list of explicit origins for tighter security
# (e.g. "http://raspberrypi.local,http://192.168.1.100").
_cors_origins_env = os.getenv('CORS_ORIGINS', '*')
allowed_origins = _cors_origins_env if _cors_origins_env == '*' else _cors_origins_env.split(',')
CORS(app, resources={
    r"/api/*": {
        "origins": allowed_origins,
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization", "X-Requested-With"],
        "supports_credentials": True
    }
})

# Load configuration
config = configparser.ConfigParser()
config.read('/app/config/config.ini')

# Service configuration
API_PORT = int(os.getenv('API_PORT', config.get('network', 'api_port', fallback='8080')))
SERVICE_NAME = config.get('general', 'service_name', fallback='ServicePi IoT')

# In-memory storage for demo (replace with database in production)
sensor_data = []
device_status = {
    'temperature_sensor': {'status': 'online', 'last_reading': 22.5, 'unit': '°C'},
    'humidity_sensor': {'status': 'online', 'last_reading': 65.2, 'unit': '%'},
    'motion_sensor': {'status': 'online', 'last_reading': False, 'unit': 'boolean'}
}

@app.route('/', methods=['GET'])
def root():
    """API root endpoint"""
    return jsonify({
        'service': SERVICE_NAME,
        'version': '1.0.0',
        'timestamp': datetime.utcnow().isoformat(),
        'endpoints': [
            '/health',
            '/api/sensors',
            '/api/sensors/data',
            '/api/devices',
            '/api/system/info',
            '/api/system/update',
            '/api/services/status'
        ]
    })

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': SERVICE_NAME,
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/api/sensors', methods=['GET'])
def get_sensors():
    """Get all sensor information"""
    return jsonify({
        'sensors': device_status,
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/api/sensors/data', methods=['GET', 'POST'])
def sensor_data_endpoint():
    """Get or post sensor data"""
    if request.method == 'GET':
        # Return recent sensor data
        return jsonify({
            'data': sensor_data[-100:],  # Last 100 readings
            'count': len(sensor_data),
            'timestamp': datetime.utcnow().isoformat()
        })
    
    elif request.method == 'POST':
        # Add new sensor reading
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        # Add timestamp if not provided
        if 'timestamp' not in data:
            data['timestamp'] = datetime.utcnow().isoformat()
        
        sensor_data.append(data)
        
        # Update device status if applicable
        if 'sensor_type' in data and data['sensor_type'] in device_status:
            device_status[data['sensor_type']]['last_reading'] = data.get('value')
            device_status[data['sensor_type']]['status'] = 'online'
        
        return jsonify({'success': True, 'data': data}), 201

@app.route('/api/devices', methods=['GET'])
def get_devices():
    """Get all device information"""
    return jsonify({
        'devices': device_status,
        'total_devices': len(device_status),
        'online_devices': sum(1 for d in device_status.values() if d['status'] == 'online'),
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/api/devices/<device_id>', methods=['GET', 'PUT'])
def device_endpoint(device_id):
    """Get or update specific device"""
    if device_id not in device_status:
        return jsonify({'error': 'Device not found'}), 404
    
    if request.method == 'GET':
        return jsonify({
            'device_id': device_id,
            'device': device_status[device_id],
            'timestamp': datetime.utcnow().isoformat()
        })
    
    elif request.method == 'PUT':
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        # Update device status
        device_status[device_id].update(data)
        return jsonify({
            'success': True,
            'device_id': device_id,
            'device': device_status[device_id]
        })

@app.route('/api/system/info', methods=['GET'])
def system_info():
    """Get system information"""
    return jsonify({
        'system': {
            'service': SERVICE_NAME,
            'uptime': 'Running',
            'version': '1.0.0',
            'api_port': API_PORT
        },
        'statistics': {
            'total_sensor_readings': len(sensor_data),
            'total_devices': len(device_status),
            'online_devices': sum(1 for d in device_status.values() if d['status'] == 'online')
        },
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/api/system/communicate', methods=['POST'])
def communicate_with_services():
    """Demonstrate inter-service communication"""
    try:
        # Example: Check if web service is healthy
        web_health = requests.get('http://web-backend:80/health', timeout=5)
        
        # Example: Get Portainer status (this would need Portainer API credentials in real use)
        portainer_status = "accessible"  # Simplified for demo
        
        return jsonify({
            'service_communication': {
                'web_backend': {
                    'status': 'healthy' if web_health.status_code == 200 else 'unhealthy',
                    'response_time': web_health.elapsed.total_seconds()
                },
                'portainer': {
                    'status': portainer_status
                }
            },
            'timestamp': datetime.utcnow().isoformat()
        })
    except Exception as e:
        app.logger.error("Exception in /api/system/communicate: %s\n%s", e, traceback.format_exc())
        return jsonify({
            'error': 'Communication failed',
            'details': 'Internal server error',
            'timestamp': datetime.utcnow().isoformat()
        }), 500

@app.route('/api/system/update', methods=['POST'])
def trigger_system_update():
    """
    Trigger system update by executing the update script.
    Note: This requires proper authentication and should only be accessible to administrators.
    In production, this should be properly secured with authentication middleware.
    """
    try:
        data = request.get_json() or {}
        app.logger.info("Update request received: %s", data)
        
        # Basic security check - require an admin token
        # In production, implement proper authentication (OAuth, JWT, etc.)
        auth_header = request.headers.get('Authorization', '')
        admin_token = os.getenv('ADMIN_TOKEN', '')
        
        # Use constant-time comparison to prevent timing attacks
        if not admin_token:
            app.logger.warning("ADMIN_TOKEN not configured")
            return jsonify({
                'error': 'Unauthorized',
                'message': 'System updates are not configured. Set ADMIN_TOKEN environment variable.',
                'timestamp': datetime.utcnow().isoformat()
            }), 401
        
        if not auth_header.startswith('Bearer '):
            app.logger.warning("Missing or invalid Authorization header from %s", request.remote_addr)
            return jsonify({
                'error': 'Unauthorized',
                'message': 'Valid authentication token required for system updates',
                'timestamp': datetime.utcnow().isoformat()
            }), 401
        
        provided_token = auth_header[7:]
        if not secrets.compare_digest(provided_token, admin_token):
            app.logger.warning("Invalid token attempt from %s", request.remote_addr)
            return jsonify({
                'error': 'Unauthorized',
                'message': 'Invalid authentication token',
                'timestamp': datetime.utcnow().isoformat()
            }), 401
        
        # In a real deployment, this would trigger the update script
        # For security, this should run with proper permissions via a privileged helper service
        
        # Since we're in a container, we'll return a response indicating
        # that the update should be triggered manually or via a proper
        # orchestration system
        
        return jsonify({
            'status': 'accepted',
            'message': 'Update request authenticated. Run the update script on the host system to complete the update.',
            'note': 'For security, automated updates must be run on the host with proper privileges.',
            'timestamp': datetime.utcnow().isoformat()
        }), 202
        
    except Exception as e:
        app.logger.error("Exception in /api/system/update: %s\n%s", e, traceback.format_exc())
        return jsonify({
            'error': 'Update request failed',
            'details': 'Internal server error',
            'timestamp': datetime.utcnow().isoformat()
        }), 500

@app.route('/api/services/status', methods=['GET'])
def get_services_status():
    """Check and return live health status of all Docker services"""
    services_to_check = [
        {'id': 'nginx',          'url': 'http://web-backend:80/health',           'timeout': 3},
        {'id': 'portainer',      'url': 'http://portainer:9000/api/system/status', 'timeout': 5},
        {'id': 'iot-api',        'url': 'http://localhost:8080/health',            'timeout': 3},
        {'id': 'homeassistant',  'url': 'http://homeassistant:8123/',              'timeout': 5},
        {'id': 'pihole',         'url': 'http://pihole:80/',                       'timeout': 3},
        {'id': 'n8n',            'url': 'http://n8n:5678/',                        'timeout': 5},
        {'id': 'wordpress',      'url': 'http://wordpress:80/',                    'timeout': 5},
        {'id': 'openwebui',      'url': 'http://openwebui:8080/',                  'timeout': 5},
        {'id': 'searxng',        'url': 'http://searxng:8080/',                    'timeout': 5},
    ]

    def check_service(service):
        try:
            resp = requests.get(
                service['url'],
                timeout=service['timeout'],
                allow_redirects=True
            )
            status = 'running' if resp.status_code < 500 else 'degraded'  # any response means container is up
            return service['id'], {
                'status': status,
                'http_status': resp.status_code,
                'response_time_ms': int(resp.elapsed.total_seconds() * 1000)
            }
        except requests.exceptions.ConnectionError:
            return service['id'], {'status': 'down'}
        except requests.exceptions.Timeout:
            return service['id'], {'status': 'timeout'}
        except Exception as exc:
            app.logger.warning("Status check failed for %s: %s", service['id'], exc)
            return service['id'], {'status': 'unknown'}

    results = {}
    max_workers = min(len(services_to_check), 10)
    with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = {executor.submit(check_service, svc): svc for svc in services_to_check}
        for future in concurrent.futures.as_completed(futures):
            service = futures[future]
            try:
                service_id, result = future.result()
                results[service_id] = result
            except Exception as exc:
                app.logger.warning(
                    "Unexpected status check failure for %s (%s): %s",
                    service['id'],
                    type(exc).__name__,
                    exc
                )
                results[service['id']] = {'status': 'unknown'}

    return jsonify({
        'services': results,
        'timestamp': datetime.utcnow().isoformat()
    })


if __name__ == '__main__':
    print(f"Starting {SERVICE_NAME} API on port {API_PORT}")
    app.run(host='0.0.0.0', port=API_PORT, debug=False)
