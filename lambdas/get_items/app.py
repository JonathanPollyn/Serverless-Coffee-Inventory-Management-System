import os
import json
import boto3
from decimal import Decimal

ddb = boto3.resource("dynamodb")

def decimal_default(obj):
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError

def handler(event, context):
    table_name = os.environ.get("TABLE_NAME")
    if not table_name:
        return {
            "statusCode": 500,
            "headers": {"content-type": "application/json"},
            "body": json.dumps({"error": "TABLE_NAME missing"})
        }

    table = ddb.Table(table_name)
    response = table.scan()
    items = response.get("Items", [])

    return {
        "statusCode": 200,
        "headers": {"content-type": "application/json"},
        "body": json.dumps(items, default=decimal_default)
    }