import boto3
import json
from google.oauth2 import id_token
from google.auth.transport.requests import Request

dynamodb_resource = boto3.resource("dynamodb")

table = dynamodb_resource.Table("lotion-30145210")

def save_handler(event, context):
    query = event.get("queryStringParameters", {})
    access = query.get("access")
    body = json.loads(event["body"])
    email = query.get("email")

    try:
        user_id = id_token.verify_oauth2_token(access, Request())
    except Exception as exp:
        print(exp)
        return {
            "statusCode": 401,
        }    

    try:
        table.put_item(Item = {
            "email": "{}".format(email),
            "id": "{}".format(body["note"]["id"]),
            "title": "{}".format(body["note"]["title"]),
            "body": "{}".format(body["note"]["body"]),
            "when": "{}".format(body["note"]["when"])
            })
        return {
            "statusCode": 201,
            "body": "success"
        }
    except Exception as exp:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(exp)})
        }