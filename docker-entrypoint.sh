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

git log --pretty=oneline --abbrev-commit -n 1

if [ ! -z "$S3_BUCKET" ]
then
    echo "Downloading saves from S3 bucket $S3_BUCKET."
    aws s3 sync s3://$S3_BUCKET/saves /opt/factorio/saves/
    if [ ! $? -eq 0 ]
    then
        exit
    fi
fi
./factorio start

trap interrupt SIGINT
trap interrupt SIGTERM

tail -f /opt/factorio/server.out -n10000