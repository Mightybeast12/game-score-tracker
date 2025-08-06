import boto3, os
def lambda_handler(event, context):
    table = boto3.resource('dynamodb').Table(os.environ['TABLE_NAME'])
    game_id = event['game_id']
    new_score = event['new_score']
    table.update_item(Key={'game_id': game_id},
                      UpdateExpression="SET score = :s",
                      ExpressionAttributeValues={':s': new_score})
    return {'statusCode': 200, 'body': 'Score updated.'}
