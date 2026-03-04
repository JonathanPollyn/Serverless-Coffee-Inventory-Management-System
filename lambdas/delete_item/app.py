import os
import json
import boto3

ddb = boto3.resource("dynamodb")

CORS_HEADERS = {
    "content-type": "application/json",
    "access-control-allow-origin": "*",
    "access-control-allow-headers": "content-type",
    "access-control-allow-methods": "GET,POST,PUT,DELETE,OPTIONS"
}

def handler(event, context):
    # DynamoDB table name injected via Terraform env var
    table_name = os.environ.get("TABLE_NAME")
    if not table_name:
        return {"statusCode": 500, "headers": CORS_HEADERS, "body": json.dumps({"error": "TABLE_NAME missing"})}

    # coffeeId comes from the URL: /inventory/{coffeeId}
    coffee_id = (event.get("pathParameters") or {}).get("coffeeId")
    if not coffee_id:
        return {"statusCode": 400, "headers": CORS_HEADERS, "body": json.dumps({"error": "Missing path param: coffeeId"})}

    table = ddb.Table(table_name)

    # Delete the record. If it doesn't exist, DynamoDB doesn't error.
    table.delete_item(Key={"coffeeId": str(coffee_id)})

    return {
        "statusCode": 204,   # 204 = success, no body
        "headers": CORS_HEADERS,
        "body": ""
    }