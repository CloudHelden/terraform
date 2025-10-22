import boto3
import json
import os
from datetime import datetime

# DynamoDB Client - boto3 ist in Lambda Runtime bereits enthalten!
dynamodb = boto3.resource('dynamodb')
TABLE_NAME = os.environ.get('DYNAMODB_TABLE')
table = dynamodb.Table(TABLE_NAME)


def handler(event, context):
    """
    Lambda Handler - Liest und schreibt zu DynamoDB
    """
    print('Event:', json.dumps(event))

    try:
        # 1. Item zu DynamoDB schreiben
        item_id = event.get('id', f'test-id-{int(datetime.now().timestamp() * 1000)}')
        item_name = event.get('name', 'Test Item')

        put_item = {
            'id': item_id,
            'name': item_name,
            'timestamp': datetime.now().isoformat()
        }

        table.put_item(Item=put_item)
        print('Item geschrieben:', put_item)

        # 2. Item von DynamoDB lesen
        response = table.get_item(Key={'id': item_id})
        result_item = response.get('Item')
        print('Item gelesen:', result_item)

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Erfolgreich!',
                'item': result_item
            })
        }

    except Exception as error:
        print('Fehler:', str(error))
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Fehler!',
                'error': str(error)
            })
        }
