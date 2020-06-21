import os

def lambda_handler(event, context):
    return "{} from Lambda!".format(os.environ['greeting'])

# TODO: Implement actual lambda function to pop records from
# kinesis and put as batches in influxdb.