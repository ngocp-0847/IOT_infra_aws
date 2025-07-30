import json
import boto3
import os
from datetime import datetime, timedelta
from decimal import Decimal

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['DYNAMODB_TABLE'])

def lambda_handler(event, context):
    """
    Lambda function để xử lý API queries cho dữ liệu IoT
    """
    
    try:
        # Parse request
        http_method = event.get('httpMethod', 'GET')
        path = event.get('path', '')
        query_params = event.get('queryStringParameters', {}) or {}
        
        # Handle CORS
        headers = {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS'
        }
        
        if http_method == 'OPTIONS':
            return {
                'statusCode': 200,
                'headers': headers,
                'body': ''
            }
        
        # Route requests
        if path == '/health':
            return health_check(headers)
        elif path == '/devices':
            return get_devices(headers, query_params)
        elif path.startswith('/devices/'):
            device_id = path.split('/')[2]
            return get_device_data(device_id, headers, query_params)
        else:
            return {
                'statusCode': 404,
                'headers': headers,
                'body': json.dumps({'error': 'Not found'})
            }
            
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        }

def health_check(headers):
    """Health check endpoint"""
    return {
        'statusCode': 200,
        'headers': headers,
        'body': json.dumps({
            'status': 'healthy',
            'timestamp': datetime.utcnow().isoformat()
        })
    }

def get_devices(headers, query_params):
    """Get list of all devices"""
    try:
        # Scan DynamoDB to get unique devices
        response = table.scan(
            ProjectionExpression='device_id',
            Select='SPECIFIC_ATTRIBUTES'
        )
        
        devices = list(set([item['device_id'] for item in response.get('Items', [])]))
        
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({
                'devices': devices,
                'count': len(devices)
            })
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        }

def get_device_data(device_id, headers, query_params):
    """Get data for specific device"""
    try:
        # Parse query parameters
        start_time = query_params.get('start_time')
        end_time = query_params.get('end_time')
        limit = int(query_params.get('limit', '100'))
        
        # Build query
        key_condition_expression = 'device_id = :device_id'
        expression_attribute_values = {':device_id': device_id}
        
        if start_time:
            key_condition_expression += ' AND timestamp_hour >= :start_time'
            expression_attribute_values[':start_time'] = start_time
            
        if end_time:
            key_condition_expression += ' AND timestamp_hour <= :end_time'
            expression_attribute_values[':end_time'] = end_time
        
        # Query DynamoDB
        response = table.query(
            KeyConditionExpression=key_condition_expression,
            ExpressionAttributeValues=expression_attribute_values,
            Limit=limit,
            ScanIndexForward=False  # Most recent first
        )
        
        # Convert Decimal to float for JSON serialization
        items = []
        for item in response.get('Items', []):
            converted_item = {}
            for key, value in item.items():
                if isinstance(value, Decimal):
                    converted_item[key] = float(value)
                else:
                    converted_item[key] = value
            items.append(converted_item)
        
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({
                'device_id': device_id,
                'data': items,
                'count': len(items),
                'last_evaluated_key': response.get('LastEvaluatedKey')
            })
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        } 