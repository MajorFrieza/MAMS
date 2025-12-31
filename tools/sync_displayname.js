// Migration: sync displayName from Firestore users collection into Auth users
// Run this with a service account on a safe environment.
// Usage: set GOOGLE_APPLICATION_CREDENTIALS and run `node sync_displayname.js`

const admin = require('firebase-admin');

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('Set GOOGLE_APPLICATION_CREDENTIALS to your service account JSON file');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();

async function sync() {
  console.log('Starting sync...');
  const usersSnap = await db.collection('users').get();
  console.log('Found', usersSnap.size, 'user docs');
  for (const doc of usersSnap.docs) {
    const uid = doc.id;
    const data = doc.data();
    const displayName = data.displayName || data.name || data.fullName || null;
    if (!displayName) {
      console.log(uid, 'no displayName to sync, skipping');
      continue;
    }

    try {
      const authUser = await admin.auth().getUser(uid);
      if (!authUser.displayName) {
        await admin.auth().updateUser(uid, { displayName });
        console.log('Updated auth displayName for', uid);
      } else if (authUser.displayName !== displayName) {
        // Optionally update if different
        await admin.auth().updateUser(uid, { displayName });
        console.log('Synced different displayName for', uid);
      } else {
        // already matches
      }
    } catch (err) {
      console.error('Error processing', uid, err.message || err);
    }
  }
  console.log('Done');
}

sync().catch(err => { console.error(err); process.exit(1); });
