# Copyright (c) 2025, Assessment: SolutionsEngineer-LarryAdah

import json
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("SwiftLineOrders")

def lambda_handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")
    
    # Lex V2 structure is nested
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
    msg_text = (
        f"Order Found!\n"
        f"Status: {item['delivery']['status']}\n"
        f"Estimated: {item['delivery']['estimatedDate']}\n"
        f"Carrier: {item['delivery']['carrier']}"
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