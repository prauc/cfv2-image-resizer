# GCS Image Resizer

Image Resizer, based on `Cloud Functions v2`, `EventArc` and `Pub/Sub`.
If file gets uploaded to source bucket, this Cloud Function is triggered to resize the image and store each in its target bucket.

## Project setup

```
chmod +x ./install.sh
./install.sh
```

## Input Parameters

### Location

Your GCP region. e.g. `europe-west4`

### Service Account Name

Service Account Name for `Service Account` to be created.

### GCP Project ID

Your GCP Project ID.

### GCS Source Bucket

Your GCS Source Bucket, where images get uploaded.

### GCS Target Bucket

Your GCS Target Bucket, where resized images should be uploaded to.
