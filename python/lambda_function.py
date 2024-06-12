import json
import boto3

def lambda_handler(event, context):
    # Connect to DB
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('resume-visitor-count')
    # Retrieve the visitor count
    response = table.get_item(
        Key={
                'ID': '1',
        }
    )
    item = response['Item']
    # Update the visitor count
    table.update_item(
        Key={
            'id': '1',
        },
        UpdateExpression='SET VisitorCount = :val1',
        ExpressionAttributeValues={
            ':val1': item['VisitorCount'] + 1
        }
    )
    response = table.get_item(
        Key={
            'ID': '1',
        }
    )
    item = response['Item']
    
    return item
