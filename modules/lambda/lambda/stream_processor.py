import json
import boto3
import os
from datetime import datetime, timedelta
from decimal import Decimal

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')
table = dynamodb.Table(os.environ['DYNAMODB_TABLE'])
s3_bucket = os.environ['S3_BUCKET']

def handler(event, context):
    """
    Lambda function để xử lý dữ liệu từ SQS queue
    Tính toán giá trị trung bình theo giờ và lưu vào DynamoDB
    """
    
    processed_records = 0
    errors = []
    
    for record in event['Records']:
        try:
            # Decode SQS message
            payload = json.loads(record['body'])
            
            # Extract data
            device_id = payload.get('device_id')
            timestamp = payload.get('timestamp')
            temperature = payload.get('temperature')
            humidity = payload.get('humidity')
            
            if not all([device_id, timestamp, temperature, humidity]):
                continue
            
            # Convert timestamp to hour bucket
            dt = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
            hour_bucket = dt.replace(minute=0, second=0, microsecond=0).isoformat()
            
            # Create DynamoDB key
            key = {
                'device_id': device_id,
                'timestamp_hour': hour_bucket
            }
            
            # Update DynamoDB with aggregated data
            response = table.update_item(
                Key=key,
                UpdateExpression="""
                    SET 
                        avg_temperature = if_not_exists(avg_temperature, :temp),
                        avg_humidity = if_not_exists(avg_humidity, :humidity),
                        #cnt = if_not_exists(#cnt, :zero),
                        min_temperature = if_not_exists(min_temperature, :temp),
                        max_temperature = if_not_exists(max_temperature, :temp),
                        min_humidity = if_not_exists(min_humidity, :humidity),
                        max_humidity = if_not_exists(max_humidity, :humidity),
                        last_updated = :now
                """,
                ExpressionAttributeNames={
                    '#cnt': 'count'
                },
                ExpressionAttributeValues={
                    ':temp': Decimal(str(temperature)),
                    ':humidity': Decimal(str(humidity)),
                    ':zero': 0,
                    ':now': datetime.utcnow().isoformat()
                },
                ReturnValues="ALL_NEW"
            )
            
            # Update averages
            current = response['Attributes']
            count = current['count'] + 1
            
            # Calculate new averages
            avg_temp = (current['avg_temperature'] * current['count'] + Decimal(str(temperature))) / count
            avg_humidity = (current['avg_humidity'] * current['count'] + Decimal(str(humidity))) / count
            
            # Update min/max values
            min_temp = min(current['min_temperature'], Decimal(str(temperature)))
            max_temp = max(current['max_temperature'], Decimal(str(temperature)))
            min_humidity = min(current['min_humidity'], Decimal(str(humidity)))
            max_humidity = max(current['max_humidity'], Decimal(str(humidity)))
            
            # Final update
            table.update_item(
                Key=key,
                UpdateExpression="""
                    SET 
                        avg_temperature = :avg_temp,
                        avg_humidity = :avg_humidity,
                        #cnt = :count,
                        min_temperature = :min_temp,
                        max_temperature = :max_temp,
                        min_humidity = :min_humidity,
                        max_humidity = :max_humidity
                """,
                ExpressionAttributeNames={
                    '#cnt': 'count'
                },
                ExpressionAttributeValues={
                    ':avg_temp': avg_temp,
                    ':avg_humidity': avg_humidity,
                    ':count': count,
                    ':min_temp': min_temp,
                    ':max_temp': max_temp,
                    ':min_humidity': min_humidity,
                    ':max_humidity': max_humidity
                }
            )
            
            processed_records += 1
            
        except Exception as e:
            errors.append(f"Error processing record: {str(e)}")
            continue
    
    # Log results
    print(f"Processed {processed_records} records")
    if errors:
        print(f"Errors: {errors}")
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'processed_records': processed_records,
            'errors': errors
        })
    } 