#!/bin/bash
set -xe

handler()
{
    echo "Interrupted!"
    ./factorio stop
    if [ ! -z "$S3_BUCKET" ]
    then
        echo "Uploading saves to S3."
        aws s3 sync --storage-class STANDARD_IA /opt/factorio/saves/ s3://$S3_BUCKET/saves
    fi
    exit
}

if [ ! -z "$SECRET_NAME" ]
then
    RCON_PASS=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME | jq -r '.SecretString')
    EXTRA_BINARGS="$EXTRA_BINARGS --rcon-bind 0.0.0.0:27015 --rcon-password $RCON_PASS"
fi

if [ ! -z "$HOSTED_ZONE" ]
then
    echo "Updating DNS route."
    PUBLIC_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
    aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE --change-batch '{"Changes":[{"Action":"UPSERT","ResourceRecordSet":{"Name":"'"$SERVER_NAME"'.'"$DOMAIN"'","ResourceRecords":[{"Value":"'"$PUBLIC_IP"'"}],"TTL":60,"Type":"A"}}]}'
fi

if [ ! -z "$S3_BUCKET" ]
then
    echo "Downloading saves from S3 bucket $S3_BUCKET."
    aws s3 sync s3://$S3_BUCKET/saves /opt/factorio/saves/
    if [ ! $? -eq 0 ]
    then
        exit
    fi
fi

if [ ! -z "$SERVER_NAME" ]
then
    echo "*/1 * * * * /opt/factorio-init/cloudwatch-metrics $SERVER_NAME" > /opt/factorio-init/crontab
    supercronic -split-logs /opt/factorio-init/crontab > /dev/null &
fi

trap handler SIGINT
trap handler SIGTERM

./factorio start $RCON

tail -f /opt/factorio/server.out -n10000 &

wait