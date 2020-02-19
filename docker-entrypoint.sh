#!/bin/bash

interrupt()
{
    ./factorio stop
    if [ ! -z "$S3_BUCKET" ]
    then
        echo "Uploading saves to S3."
        aws s3 sync --storage-class STANDARD_IA /opt/factorio/saves/ s3://$S3_BUCKET/saves
    fi
    exit
}

if [ ! -z "$S3_BUCKET" ]
then
    echo "Downloading saves from S3."
    aws s3 sync s3://$S3_BUCKET/saves /opt/factorio/saves/
    if [ ! $? -eq 0 ]
    then
        exit
    fi
fi
./factorio start

trap interrupt SIGINT

tail -f /opt/factorio/server.out -n10000