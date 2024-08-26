#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <file>"
    exit 1
fi

FILE_PATH=$1
CHANNEL_ID="C12345678"  # Replace with your channel ID
TOKEN="hoge"

# Step 1: Get Upload URL
response=$(curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"channels":"'"$CHANNEL_ID"'"}' \
  https://slack.com/api/files.getUploadURLExternal)

upload_url=$(echo $response | jq -r '.upload_url')
file_id=$(echo $response | jq -r '.file_id')

# Step 2: Upload the File
curl -X PUT -F file=@"$FILE_PATH" "$upload_url"

# Step 3: Complete the Upload
curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"file_id":"'"$file_id"'"}' \
  https://slack.com/api/files.completeUploadExternal
