import boto3
import json
import os
from boto3.dynamodb.conditions import Key
from decimal import Decimal

def decimal_default(obj):
    if isinstance(obj, Decimal):
        return int(obj)
    raise TypeError

def lambda_handler(event, context):
    try:
        table = boto3.resource('dynamodb').Table(os.environ['TABLE_NAME'])
        
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        game_id = body.get('game_id')
        scoring_player = body.get('player')  # 'player1' or 'player2'
        
        if not game_id or not scoring_player:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'game_id and player are required'}, default=decimal_default)
            }
        
        # Get current game state
        response = table.get_item(Key={'game_id': game_id})
        if 'Item' not in response:
            return {
                'statusCode': 404,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'Game not found'}, default=decimal_default)
            }
        
        game = response['Item']
        
        if game.get('status') != 'active':
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'Game is not active'}, default=decimal_default)
            }
        
        # Tennis scoring logic
        points = game['points']
        games = game['games']
        sets = game['sets']
        
        # Add point to scoring player
        points[scoring_player] += 1
        
        # Check for game win
        other_player = 'player2' if scoring_player == 'player1' else 'player1'
        
        if points[scoring_player] >= 4 and points[scoring_player] - points[other_player] >= 2:
            # Game won
            games[scoring_player] += 1
            points = {'player1': 0, 'player2': 0}
            
            # Check for set win
            if games[scoring_player] >= 6 and games[scoring_player] - games[other_player] >= 2:
                sets[scoring_player] += 1
                games = {'player1': 0, 'player2': 0}
                
                # Check for match win (best of 3 sets)
                if sets[scoring_player] >= 2:
                    game['status'] = 'completed'
                    game['winner'] = scoring_player
        
        # Update game state
        game['points'] = points
        game['games'] = games
        game['sets'] = sets
        
        table.put_item(Item=game)
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'game_id': game_id,
                'points': points,
                'games': games,
                'sets': sets,
                'status': game['status'],
                'winner': game.get('winner')
            }, default=decimal_default)
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': str(e)}, default=decimal_default)
        }
