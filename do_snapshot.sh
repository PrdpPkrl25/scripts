#!/bin/bash

DROPLET_ID="YOUR-DROPLET_ID"
DAY=`date '+%Y-%m-%d'`
SNAPSHOT_NAME="SNAPSHOT_NAME-"$DAY""
TOKEN="YOUR_DO_API_TOKEN"
DATE=$(date -u -d '7 days ago' +"%Y-%m-%dT%H:%M:%S.%NZ") #TO DELETE SNAPSHOT OLDER THAN 7 days

# Get all the snapshots for this droplet
SNAPSHOT_IDS=$(curl -s -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" "https://api.digitalocean.com/v2/droplets/$DROPLET_ID/snapshots" | jq -r '.snapshots[] | select(.created_at < "'$DATE'" and .type == "snapshot") | .id')

# Loop through all the snapshots and delete them
for SNAPSHOT_ID in $SNAPSHOT_IDS
do
  echo "Deleting snapshot with ID $SNAPSHOT_ID..."
  curl -X DELETE -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" "https://api.digitalocean.com/v2/snapshots/$SNAPSHOT_ID"
done

# Take a new snapshot
echo "Taking new snapshot: $SNAPSHOT_NAME"
curl -X POST "https://api.digitalocean.com/v2/droplets/$DROPLET_ID/actions" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"type":"snapshot", "name":"'"$SNAPSHOT_NAME"'"}'
