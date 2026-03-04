import os
import json
import boto3
import base64
from decimal import Decimal

ddb = boto3.resource("dynamodb")

def handler(event, context):
    table_name = os.environ.get("TABLE_NAME")
    if not table_name:
        return {
            "statusCode": 500,
            "headers": {"content-type": "application/json"},
            "body": json.dumps({"error": "TABLE_NAME env var missing"})
        }

    body = event.get("body")

    if event.get("isBase64Encoded"):
        body = base64.b64decode(body).decode("utf-8")

    if isinstance(body, str):
        try:
            body = json.loads(body)
        except Exception:
            return {
                "statusCode": 400,
                "headers": {"content-type": "application/json"},
                "body": json.dumps({"error": "Invalid JSON body"})
            }

    if not isinstance(body, dict):
        return {
            "statusCode": 400,
            "headers": {"content-type": "application/json"},
            "body": json.dumps({"error": "Body must be JSON"})
        }

    required = ["coffeeId", "name", "price", "available"]
    missing = [k for k in required if k not in body]
    if missing:
        return {
            "statusCode": 400,
            "headers": {"content-type": "application/json"},
            "body": json.dumps({"error": f"Missing fields: {missing}"})
        }

    item = {
        "coffeeId": str(body["coffeeId"]),
        "name": str(body["name"]),
        "price": Decimal(str(body["price"])),
        "available": bool(body["available"])
    }

    table = ddb.Table(table_name)
    table.put_item(Item=item)

    return {
        "statusCode": 201,
        "headers": {"content-type": "application/json"},
        "body": json.dumps(item, default=str)
    }