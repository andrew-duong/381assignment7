import boto3
from boto3.dynamodb.conditions import Key
import json
from google.oauth2 import id_token
from google.auth.transport.requests import Request


dynamodb_resource = boto3.resource("dynamodb")


table = dynamodb_resource.Table("lotion-30145210")


def get_handler(event, context):
    query = event.get("queryStringParameters", {})
    user = query.get("email")
    access = query.get("access")

    try:
        user_id = id_token.verify_oauth2_token(access, Request())
    except Exception as exp:
        print(exp)
        return {
            "statusCode": 401,
        }    
        
    try:
        response = table.query(KeyConditionExpression=Key("email").eq(user))
        item = response["Items"]
        return {
            "statusCode": 200,
            "body": json.dumps(item)
            }
    except Exception as exp:
        print(str(exp))
        return {
            "statusCode": 500,
            "body": None
            }



