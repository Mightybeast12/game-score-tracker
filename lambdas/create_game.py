import boto3
import uuid
import json
import os
from datetime import datetime

def lambda_handler(event, context):
    try:
        table = boto3.resource('dynamodb').Table(os.environ['TABLE_NAME'])
        
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        player1 = body.get('player1', 'Player 1')
        player2 = body.get('player2', 'Player 2')
        game_type = body.get('gameType', 'tennis')
        
        game_id = str(uuid.uuid4())
        
        # Game scoring structure
        game_item = {
            'game_id': game_id,
            'player1': player1,
            'player2': player2,
            'game_type': game_type,
            'sets': {
                'player1': 0,
                'player2': 0
            },
            'games': {
                'player1': 0,
                'player2': 0
            },
            'points': {
                'player1': 0,
                'player2': 0
            },
            'status': 'active',
            'created_at': datetime.utcnow().isoformat(),
            'winner': None
        }
        
        table.put_item(Item=game_item)
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'game_id': game_id,
                'message': f'Tennis game created between {player1} and {player2}'
            })
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
