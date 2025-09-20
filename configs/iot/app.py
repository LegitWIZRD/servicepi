#!/usr/bin/env python3
"""
ServicePi IoT API Service
Provides REST API for IoT device management and sensor data
"""

import os
import json
import configparser
from datetime import datetime
from flask import Flask, jsonify, request
import requests

app = Flask(__name__)

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
            '/api/system/info'
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
            'api_port': API_PORT,
            'ssl_enabled': os.getenv('SSL_ENABLED', 'false').lower() == 'true'
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
        return jsonify({
            'error': 'Communication failed',
            'details': str(e),
            'timestamp': datetime.utcnow().isoformat()
        }), 500

if __name__ == '__main__':
    print(f"Starting {SERVICE_NAME} API on port {API_PORT}")
    app.run(host='0.0.0.0', port=API_PORT, debug=False)