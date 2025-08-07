import boto3
import json
import os
from decimal import Decimal

def decimal_default(obj):
    if isinstance(obj, Decimal):
        return int(obj)
    raise TypeError

def lambda_handler(event, context):
    try:
        table = boto3.resource('dynamodb').Table(os.environ['TABLE_NAME'])
        
        # Scan all games, ordered by creation date
        response = table.scan()
        games = response['Items']
        
        # Sort by created_at descending (newest first)
        games.sort(key=lambda x: x.get('created_at', ''), reverse=True)
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'games': games
            }, default=decimal_default)
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': str(e)})
        }