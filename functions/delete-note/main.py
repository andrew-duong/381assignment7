import boto3
import json
from google.oauth2 import id_token
from google.auth.transport.requests import Request

dynamodb_resource = boto3.resource("dynamodb")

table = dynamodb_resource.Table("lotion-30145210")

def delete_handler(event, context):
    query = event.get("queryStringParameters", {})
    email = query.get("email")
    id = query.get("id")
    access = query.get("access")
    
    try:
        user_id = id_token.verify_oauth2_token(access, Request())
    except Exception as exp:
        print(exp)
        return {
            "statusCode": 401,
        }   

    if access == None:
        return {
            "statusCode": 401 
        }
    
    try:
        table.delete_item(Key = {
            "email": "{}".format(email),
            "id": "{}".format(id)
        })
        return {
            "statusCode": 200,
            "body": "success"
        }
    except Exception as exp:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(exp)})
        }