import re
import json
import requests
import boto3
import logging
import uuid
import time
import os
from boto3.dynamodb.conditions import Attr
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)

api_token = 'xoxb-6723481479-781607013413-adzXobqcDZx1cWs75rGofrPR'
api_url_base = 'https://slack.com/api/chat.postMessage'
headers = {
    'Content-Type': 'application/json;charset=utf-8',
    'Authorization': 'Bearer {0}'.format(api_token)
}

dynamodb = boto3.resource('dynamodb')
# TODO: Find a better name for this table
table = dynamodb.Table('prod-noisealertreporttable')


# PAYLOAD Winston
# json: {
#     "reporter": "jose.carballo", <- REQUIRED *
#     "location": {
#         "floor": 10, <- REQUIRED *
#         "zone": "east-wing",
#         "column": "column-8"
#     }
#     "force": false,
#     "msg": "" <-Optional  *
# }

# PAYLOAD Slackcommand
# json: {
#     "user_name": "jose.carballo", <- REQUIRED *
#     "text": "10" <- REQUIRED *
# }


def post_handler(event, context):
    slackcommand = False
    logger.info(f"Received event: {event}")

    event['DataID'] = str(uuid.uuid4())

    # Anti-spam protection
    hours = 120  # Default: 60
    protection_start = int((time.time() - (60 * hours)) * 1000000)  #

    now = int(time.time() * 1000000)
    event['CreatedAt'] = now
    event['Enabled'] = os.environ.get('enabled', 'true') == 'true'

    last_sent_filter = Attr('CreatedAt').between(protection_start, now) & \
        Attr('Delayed').eq(False) & Attr('Enabled').eq(True)
    logger.info(f"Using spam protection of {hours} hours.")
    event['Delayed'] = len(
        table.scan(FilterExpression=last_sent_filter)['Items']) > 0
    logger.info(f"Is Event Delayed ?. {'YES' if event['Delayed'] else 'NO'}")

    table.put_item(
        Item=event
    )

    reporter = event.get('reporter')
    if not reporter:
        # Slackcommand event
        reporter = event.get('user_name')
        slackcommand = True

    if not reporter:
        return format_response(slackcommand, "Missing Reporter", 500)

    # Support only 9:00 AM - 4:00PM, excluding lunch hour 12:00 PM,
    # Costa Rica (UTC-6)
    utc_now = datetime.now()
    start_hour = 9 + 6
    lunch_hour = 12 + 6
    end_hour = 16 + 6
    if utc_now.hour < start_hour or \
            utc_now.hour > end_hour or \
            utc_now.hour == lunch_hour:
        return format_response(slackcommand, "Hey! I'm only available from "
                                             "9:00 AM to 12:00 PM and from "
                                             "1:00 PM to 4:00 PM, UTC-6. "
                                             "Cheers!", 200)

    floor = event.get('location', {}).get('floor')
    if not floor:
        # Slackcommand event
        floor = event.get('text')

    if not floor:
        return format_response(slackcommand, "Missing Floor", 500)

    if not re.match(r"(7|10)", str(floor)):
        return format_response(slackcommand, "Wrong floor, only 7 and 10 are "
                                             "allowed", 500)

    # TODO something should validate that there is a minimal amount
    count = 1

    msg = event.get("msg")

    if not msg:
        if count == 1:
            amount_msg = "a noise alert"
        else:
            amount_msg = "{0} noise alerts".format(count)
        # msg = "*Noise Alert* <!here>! We have received {0} on the {1}th
        # floor; please consider lowering your voice.".format(amount_msg,
        # floor)
        msg = "*Noise Alert* We have received {0} on the {1}th floor; please " \
              "consider lowering your voice.".format(amount_msg, floor)

    data = {
        "channel": "#costarica",
        "text": msg
    }

    try:
        if event['Delayed']:
            return format_response(slackcommand, "Thanks for your alert! The "
                                                 "event was recorded, but we "
                                                 "reported an alert less than "
                                                 "2 hours ago. Please try "
                                                 "again in a while, or ask "
                                                 "nicely to your fellow "
                                                 "Gorilla to keep it down. "
                                                 "Cheers!", 200)
        elif event['Enabled']:
            r = requests.post(url=api_url_base, headers=headers, json=data)

            response_json = r.json()

            if not response_json['ok']:
                return format_response(slackcommand, response_json, 500)
            else:
                if slackcommand:
                    return format_response(slackcommand, 'Thanks for your '
                                                         'alert!', 200)
                return format_response(slackcommand, response_json, 200)
        else:
            return format_response(slackcommand, 'The event was recorded but '
                                                 'today the alerts are '
                                                 'disabled', 200)
    except Exception as e:
        return format_response(slackcommand, str(e), 500)


def format_response(slackcommand, message, status_code):
    logging.info(f"Response for {slackcommand} with status {status_code}:"
                 f" {message}")
    if slackcommand:
        # Following https://api.slack.com/slash-commands
        # Confirming receipt
        return {
            "response_type": "ephemeral",
            "text": message
        }
    else:
        if status_code == 500:
            return {
                "status_code": status_code,
                "body": json.dumps(
                    {
                        "error": message
                    }
                )
            }
        else:
            return {
                "status_code": status_code,
                "body": json.dumps(
                    {
                        "success": message
                    }
                )
            }
