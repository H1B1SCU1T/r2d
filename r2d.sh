#!/bin/bash

DAYS=$5

AFTER=$(date --date "${DAYS} day ago" '+%s')
SUBREDDIT=$3

# https://stedolan.github.io/jq/tutorial/
POSTS=$(curl "https://api.pushshift.io/reddit/search/submission/?subreddit=${SUBREDDIT}&sort=desc&sort_type=created_utc&after=${AFTER}" \
    | jq -rc '.data[] | {full_link: .full_link, title: .title, thumbnail: .thumbnail, "author": .author} | @base64')

# bot data
USERNAME=$1
AVATAR_URL=$2
WEBHOOK=$4

for i in $POSTS; do 
    DECODED=$(echo $i | base64 --decode)

    TITLE=$(echo $DECODED | jq .title)
    URL=$(echo $DECODED | jq .full_link)
    THUMBNAIL_URL=$(echo $DECODED | jq .thumbnail)
    AUTHOR_NAME=$(echo $DECODED | jq .author)


    # https://discord.com/developers/docs/resources/webhook#execute-webhook
    # https://discord.com/developers/docs/resources/channel#embed-object

    PAYLOAD="{\"username\":\"${USERNAME}\",\"avatar_url\":\"${AVATAR_URL}\",\"embeds\":[{\"title\":${TITLE},\"url\":${URL},\"thumbnail\":{\"url\":${THUMBNAIL_URL}},\"author\":{\"name\":${AUTHOR_NAME}}}]}"

    # curl throws a fit about the format of the json when provied inline. Passing as a file is fine
    echo $PAYLOAD | jq '.' > payload.json

    curl \
        -X POST \
        -g \
        -d @payload.json \
        -H 'Content-Type: application/json' \
        --url $WEBHOOK
done

if [ -f "./payload.json" ]; then
   rm ./payload.json
fi