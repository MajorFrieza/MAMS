Migration tools

sync_displayname.js
- Purpose: copies `displayName`/`name`/`fullName` from Firestore `users` collection into Firebase Auth user records.
- Usage:
  1. Create a Firebase service account and download the JSON file.
  2. Set `GOOGLE_APPLICATION_CREDENTIALS` environment variable to the JSON path.
  3. Run: `node tools/sync_displayname.js`

Notes:
- Test in staging first.
- Backup Firestore (export) before running in production.
