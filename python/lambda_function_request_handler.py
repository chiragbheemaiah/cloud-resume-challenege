import json
import boto3 # type: ignore

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
    
    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*',  # Allow all origins
        },
        'body': item['VisitorCount']
    }
