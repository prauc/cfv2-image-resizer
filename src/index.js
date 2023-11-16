'use strict';

// [START functions_cloudevent_storage]
const functions = require('@google-cloud/functions-framework');
const { Storage } = require('@google-cloud/storage');
const sharp = require('sharp');
const path = require('path');

const destBucketName = process.env.targetBucket;

// Register a CloudEvent callback with the Functions Framework that will
// be triggered by Cloud Storage.
functions.cloudEvent('imageResizeGCS', cloudEvent => {
  const file = cloudEvent.data;

  downloadFile(file.bucket, file.name)
    .then((response) => {
      const rawFilename = path.parse(file.name).name
      transferFile(rawFilename, file.name, response[0], 'original').catch(console.error);

      [160, 320, 768, 1400].forEach(size => {
        resize(response[0], size)
          .then((resizedImageContents) => transferFile(rawFilename, `${rawFilename}-${size}px.png`, resizedImageContents, size))
          .catch(console.error);
      });
    });
});

function resize(contents, size) {
  return sharp(contents)
    .resize(size)
    .png()
    .toBuffer();
}

function downloadFile(srcBucketName, file) {
  const storage = new Storage();
  return storage.bucket(srcBucketName).file(file).download();
}

function transferFile(folder, file, contents, size) {
  let storage = new Storage();
  console.log(`Copying file ${file} to Bucket ${destBucketName}, with size ${size}`)

  const copyDestination = storage.bucket(destBucketName).file(`${folder}/${file}`);
  copyDestination.save(contents, { resumable: false });
}
// [END functions_cloudevent_storage]