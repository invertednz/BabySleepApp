# Data Folder

This folder contains seed data and sample content for the Baby Language app.

## Files

- Language milestone seed data is in `../sample_language_milestones_seed.json`
- To import to Firestore, use Firebase Console or a custom import script

## Importing to Firestore

### Option 1: Firebase Console
1. Go to Firestore Database in Firebase Console
2. Navigate to `language_milestones` collection
3. Manually add documents or use the import feature

### Option 2: Node.js Script
```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');
const milestones = require('../sample_language_milestones_seed.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function importMilestones() {
  const batch = db.batch();
  
  milestones.forEach((milestone) => {
    const docRef = db.collection('language_milestones').doc();
    batch.set(docRef, milestone);
  });
  
  await batch.commit();
  console.log('Imported', milestones.length, 'milestones');
}

importMilestones();
```
