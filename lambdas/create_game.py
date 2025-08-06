import boto3, uuid, os
def lambda_handler(event, context):
    table = boto3.resource('dynamodb').Table(os.environ['TABLE_NAME'])
    game_id = str(uuid.uuid4())
    table.put_item(Item={'game_id': game_id, 'players': [], 'score': 0})
    return {'statusCode': 200, 'body': f"Game created with ID: {game_id}"}
