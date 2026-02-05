# Firestore Index Configuration

## Problem
The app works on Chrome but fails on mobile devices because Firestore queries with `orderBy` require composite indexes that are automatically handled in web but must be explicitly created for mobile apps.

## Solution

### Option 1: Automatic Index Creation (Recommended)
1. Run the app on your mobile device
2. When the error occurs, check the Flutter console/logcat
3. Firebase will provide a direct link to create the index
4. Click the link and it will open Firebase Console with the index pre-configured
5. Click "Create Index" and wait for it to build (usually 1-2 minutes)

### Option 2: Manual Index Creation
Go to [Firebase Console](https://console.firebase.google.com) and create these indexes:

#### Lost Items Index
- **Collection**: `lost_items`
- **Fields**:
  - `createdAt` - Descending
- **Query Scope**: Collection

#### Found Items Index
- **Collection**: `found_items`
- **Fields**:
  - `createdAt` - Descending
- **Query Scope**: Collection

### Steps to Create Manually:
1. Go to Firebase Console → Your Project
2. Navigate to **Firestore Database** → **Indexes** tab
3. Click **Create Index**
4. Enter the collection name (`lost_items` or `found_items`)
5. Add field: `createdAt` with `Descending` order
6. Click **Create Index**
7. Wait for the index to build (status will change from "Building" to "Enabled")
8. Repeat for the other collection

### Option 3: Use firestore.indexes.json (Advanced)
Create a file at the root of your project:

```json
{
  "indexes": [
    {
      "collectionGroup": "lost_items",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "found_items",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
}
```

Then deploy using Firebase CLI:
```bash
firebase deploy --only firestore:indexes
```

## Verification
After creating the indexes:
1. Wait for the index status to show "Enabled" in Firebase Console
2. Restart your mobile app
3. The Lost and Found page should now load properly

## Notes
- The code has been updated with fallback error handling that will work even without indexes (items will be sorted in memory)
- However, creating the indexes is recommended for better performance
- Web apps don't require these indexes because Firebase handles it differently for web clients
