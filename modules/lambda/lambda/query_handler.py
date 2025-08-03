import json
import boto3
import os
import logging
from datetime import datetime, timedelta
from decimal import Decimal

# Cấu hình logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['DYNAMODB_TABLE'])

def handler(event, context):
    """
    Lambda function để xử lý API queries cho dữ liệu IoT
    """
    
    # Log request details
    logger.info(f"Lambda function started - Request ID: {context.aws_request_id}")
    logger.info(f"Event: {json.dumps(event, default=str)}")
    
    try:
        # Parse request - support both API Gateway V1 and V2 formats
        # API Gateway V2 format
        if 'requestContext' in event and 'http' in event['requestContext']:
            http_method = event['requestContext']['http']['method']
            path = event['requestContext']['http']['path']
            query_params = event.get('queryStringParameters', {}) or {}
            
            # Strip stage name from path for API Gateway V2
            stage = event['requestContext'].get('stage', '')
            if stage and path.startswith(f'/{stage}'):
                path = path[len(f'/{stage}'):]
                
        # API Gateway V1 format (fallback)
        else:
            http_method = event.get('httpMethod', 'GET')
            path = event.get('path', '')
            query_params = event.get('queryStringParameters', {}) or {}
        
        logger.info(f"Processing request - Method: {http_method}, Path: {path}, Query params: {query_params}")
        
        # Handle CORS
        headers = {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS'
        }
        
        if http_method == 'OPTIONS':
            logger.info("Handling OPTIONS request for CORS")
            return {
                'statusCode': 200,
                'headers': headers,
                'body': ''
            }
        
        # Route requests
        if path == '/health':
            logger.info("Routing to health check endpoint")
            return health_check(headers)
        elif path == '/devices':
            logger.info("Routing to get devices endpoint")
            return get_devices(headers, query_params)
        elif path.startswith('/devices/'):
            device_id = path.split('/')[2]
            logger.info(f"Routing to get device data endpoint for device: {device_id}")
            return get_device_data(device_id, headers, query_params)
        else:
            logger.warning(f"Invalid path requested: {path}")
            return {
                'statusCode': 404,
                'headers': headers,
                'body': json.dumps({'error': 'Not found'})
            }
            
    except Exception as e:
        logger.error(f"Error in handler: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        }

def health_check(headers):
    """Health check endpoint"""
    logger.info("Executing health check")
    response = {
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat()
    }
    logger.info(f"Health check response: {response}")
    return {
        'statusCode': 200,
        'headers': headers,
        'body': json.dumps(response)
    }

def get_devices(headers, query_params):
    """Get list of all devices"""
    logger.info("Starting get_devices operation")
    try:
        # Scan DynamoDB to get unique devices
        logger.info("Scanning DynamoDB table for devices")
        response = table.scan(
            ProjectionExpression='device_id',
            Select='SPECIFIC_ATTRIBUTES'
        )
        
        devices = list(set([item['device_id'] for item in response.get('Items', [])]))
        logger.info(f"Found {len(devices)} unique devices: {devices}")
        
        result = {
            'devices': devices,
            'count': len(devices)
        }
        logger.info(f"Get devices response: {result}")
        
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps(result)
        }
    except Exception as e:
        logger.error(f"Error in get_devices: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        }

def get_device_data(device_id, headers, query_params):
    """Get data for specific device"""
    logger.info(f"Starting get_device_data for device: {device_id}")
    logger.info(f"Query parameters: {query_params}")
    
    try:
        # Parse query parameters
        start_time = query_params.get('start_time')
        end_time = query_params.get('end_time')
        limit = int(query_params.get('limit', '100'))
        
        logger.info(f"Parsed parameters - start_time: {start_time}, end_time: {end_time}, limit: {limit}")
        
        # Build query
        key_condition_expression = 'device_id = :device_id'
        expression_attribute_values = {':device_id': device_id}
        
        # For DynamoDB composite key, we can only use one range condition
        if start_time and end_time:
            key_condition_expression += ' AND timestamp_hour BETWEEN :start_time AND :end_time'
            expression_attribute_values[':start_time'] = start_time
            expression_attribute_values[':end_time'] = end_time
            logger.info(f"Added time range filter: {start_time} to {end_time}")
        elif start_time:
            key_condition_expression += ' AND timestamp_hour >= :start_time'
            expression_attribute_values[':start_time'] = start_time
            logger.info(f"Added start_time filter: {start_time}")
        elif end_time:
            key_condition_expression += ' AND timestamp_hour <= :end_time'
            expression_attribute_values[':end_time'] = end_time
            logger.info(f"Added end_time filter: {end_time}")
        
        logger.info(f"Query expression: {key_condition_expression}")
        logger.info(f"Expression attribute values: {expression_attribute_values}")
        
        # Query DynamoDB
        logger.info("Executing DynamoDB query")
        response = table.query(
            KeyConditionExpression=key_condition_expression,
            ExpressionAttributeValues=expression_attribute_values,
            Limit=limit,
            ScanIndexForward=False  # Most recent first
        )
        
        logger.info(f"DynamoDB query completed - Items found: {len(response.get('Items', []))}")
        
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
        
        result = {
            'device_id': device_id,
            'data': items,
            'count': len(items),
            'last_evaluated_key': response.get('LastEvaluatedKey')
        }
        
        logger.info(f"Get device data response - Device: {device_id}, Count: {len(items)}")
        if items:
            logger.info(f"Sample data item: {items[0]}")
        
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps(result)
        }
        
    except Exception as e:
        logger.error(f"Error in get_device_data for device {device_id}: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        } 