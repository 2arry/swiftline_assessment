# Copyright (c) 2025, Assessment: SolutionsEngineer-candidate-larry

import json
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("SwiftLineOrdersLarry")

def lambda_handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")
    
    # Parse Input from Lex V2 because Lex V2 structure is nested
    session_state = event.get("sessionState", {})
    intent = session_state.get("intent", {})
    slots = intent.get("slots", {})
    
    # Extract Tracking ID safely
    tracking_slot = slots.get("TrackingID")
    if not tracking_slot or not tracking_slot.get("value"):
        return close_lex(intent["name"], "Fulfilled", "I didn't catch the tracking number.")
        
    tracking_id = tracking_slot["value"]["originalValue"]
    
    # Query DynamoDB
    try:
        response = table.get_item(Key={"trackingId": tracking_id})
    except Exception as e:
        logger.error(f"DB Error: {str(e)}")
        return close_lex(intent["name"], "Failed", "Sorry, I encountered a database error.")

    if "Item" not in response:
        return close_lex(intent["name"], "Fulfilled", f"I couldn't find an order with ID {tracking_id}. Please check the number.")
        
    # Format Response
    item = response["Item"]

    # Safe Extraction to handle missing keys
    cust = item.get("customer", {})
    dlv = item.get("delivery", {})
    details = item.get("orderDetails", {})
    items_list = details.get("items", [])
    
    # Build Items String
    items_str = ""
    for prod in items_list:
        qty = int(prod.get("quantity", 1)) 
        items_str += f"- {qty}x {prod.get('name')} (Vendor: {prod.get('vendor')})\n"

    # Construct the final formatted message
    msg_text = (
        f"Order Status: {dlv.get('status', 'Unknown')}\n"
        f"--------------------------------\n"
        f"Tracking ID: {item.get('trackingId')}\n\n"
        f"Order Date: {item.get('orderDate')}\n"

        f"Order Details\n"
        f"{items_str}\n"
        
        f"Customer Details\n"
        f"Name: {cust.get('name')}\n"
        f"Phone: {cust.get('phone')}\n"
        f"Email: {cust.get('email')}\n\n"
        
        f"Delivery Information\n"
        f"Carrier: {dlv.get('carrier')}\n"
        f"ETA: {dlv.get('estimatedDate')}"
    )
    
    return close_lex(intent["name"], "Fulfilled", msg_text)

def close_lex(intent_name, state, message):
    return {
        "sessionState": {
            "dialogAction": {"type": "Close"},
            "intent": {"name": intent_name, "state": state}
        },
        "messages": [{"contentType": "PlainText", "content": message}]
    }