#!/bin/bash

echo Please enter GCP Location:
read LOCATION
echo Ok, GCP Location set to: $LOCATION

echo Please enter GCP Project ID:
read PROJECT_ID
echo Ok, GCP Project ID set to: $PROJECT_ID

echo Please enter GCP Service Account Name:
read SERVICEACCOUNT_NAME
echo Ok, GCP Service Account set to: $SERVICEACCOUNT_NAME

echo Please enter GCS Source Storage Bucket:
read GCS_SOURCE
echo Ok, GCS Source Storage Bucket set to: $GCS_SOURCE

echo Please enter GCS Target Storage Bucket:
read GCS_TARGET
echo Ok, GCS Target Storage Bucket set to: $GCS_TARGET

PROJECT_NUMBER=$(gcloud projects list --filter="project_id:$PROJECT_ID" --format='value(project_number)')

echo Creating Service-Account..
gcloud iam service-accounts create $SERVICEACCOUNT_NAME

SERVICEACCOUNT="${SERVICEACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
echo $SERVICEACCOUNT

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member "serviceAccount:$SERVICEACCOUNT" \
    --role "roles/eventarc.eventReceiver"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member "serviceAccount:$SERVICEACCOUNT" \
    --role "roles/storage.objectUser"

GCS_SERVICEACCOUNT=$(gsutil kms serviceaccount -p $PROJECT_NUMBER)

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$GCS_SERVICEACCOUNT \
  --role roles/pubsub.publisher

gcloud storage buckets create gs://$GCS_SOURCE --location=$LOCATION
gcloud storage buckets create gs://$GCS_TARGET --location=$LOCATION

gcloud functions deploy nodejs-image-resize-function \
  --gen2 \
  --runtime=nodejs20 \
  --region=$LOCATION \
  --source=./src \
  --entry-point=imageResizeGCS \
  --trigger-service-account=$SERVICEACCOUNT \
  --trigger-event-filters="type=google.cloud.storage.object.v1.finalized" \
  --trigger-event-filters="bucket=$GCS_SOURCE" \
  --set-env-vars="targetBucket=$GCS_TARGET"

gcloud functions add-invoker-policy-binding nodejs-image-resize-function \
  --region="europe-west4" \
  --member="serviceAccount:$SERVICEACCOUNT"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com \
  --role=roles/iam.serviceAccountTokenCreator