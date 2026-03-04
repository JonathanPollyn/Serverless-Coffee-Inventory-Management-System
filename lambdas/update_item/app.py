import os
import json
import boto3
import base64
from decimal import Decimal

ddb = boto3.resource("dynamodb")

CORS_HEADERS = {
    "content-type": "application/json",
    "access-control-allow-origin": "*",
    "access-control-allow-headers": "content-type",
    "access-control-allow-methods": "GET,POST,PUT,DELETE,OPTIONS"
}

def decimal_default(obj):
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError

def parse_body(event):
    body = event.get("body")
    if event.get("isBase64Encoded"):
        body = base64.b64decode(body).decode("utf-8")
    if body is None:
        return {}
    if isinstance(body, str):
        return json.loads(body)
    if isinstance(body, dict):
        return body
    raise ValueError("Body must be JSON")

def handler(event, context):
    table_name = os.environ.get("TABLE_NAME")
    if not table_name:
        return {"statusCode": 500, "headers": CORS_HEADERS, "body": json.dumps({"error": "TABLE_NAME missing"})}

    coffee_id = (event.get("pathParameters") or {}).get("coffeeId")
    if not coffee_id:
        return {"statusCode": 400, "headers": CORS_HEADERS, "body": json.dumps({"error": "Missing path param: coffeeId"})}

    try:
        body = parse_body(event)
    except Exception:
        return {"statusCode": 400, "headers": CORS_HEADERS, "body": json.dumps({"error": "Invalid JSON body"})}

    allowed = {"name", "price", "available"}
    updates = {k: body[k] for k in body.keys() if k in allowed}
    if not updates:
        return {"statusCode": 400, "headers": CORS_HEADERS, "body": json.dumps({"error": "Provide at least one of: name, price, available"})}

    expr_names = {}
    expr_values = {}
    set_parts = []

    if "name" in updates:
        expr_names["#n"] = "name"
        expr_values[":name"] = str(updates["name"])
        set_parts.append("#n = :name")

    if "price" in updates:
        expr_names["#p"] = "price"
        expr_values[":price"] = Decimal(str(updates["price"]))
        set_parts.append("#p = :price")

    if "available" in updates:
        expr_names["#a"] = "available"
        expr_values[":available"] = bool(updates["available"])
        set_parts.append("#a = :available")

    table = ddb.Table(table_name)
    resp = table.update_item(
        Key={"coffeeId": str(coffee_id)},
        UpdateExpression="SET " + ", ".join(set_parts),
        ExpressionAttributeNames=expr_names,
        ExpressionAttributeValues=expr_values,
        ReturnValues="ALL_NEW"
    )

    return {
        "statusCode": 200,
        "headers": CORS_HEADERS,
        "body": json.dumps(resp.get("Attributes", {}), default=decimal_default)
    }