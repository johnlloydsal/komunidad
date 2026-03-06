# Admin Dashboard Field Names - Flutter App Compatibility

## ⚠️ CRITICAL: Use These Exact Field Names

This document defines the **required Firestore field names** that your admin dashboard must use to ensure compatibility with the Flutter mobile app.

---

## 📋 Reports Collection (`reports`)

### When Taking Action on a Report

When an admin takes action (status: `actioned` or `in-progress`):

```javascript
await firebase.firestore().collection('reports').doc(reportId).update({
  status: 'actioned',  // or 'in-progress'
  actionNotes: "Your action notes here",  // ✅ REQUIRED: Use 'actionNotes' (plural)
  actionedAt: firebase.firestore.FieldValue.serverTimestamp(),
  updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
});
```

**Field Name: `actionNotes`** (plural, camelCase)
- ❌ NOT: `actionNote`, `action_notes`, `notes`
- ✅ USE: `actionNotes`

### When Marking Report as Resolved

When an admin resolves a report (status: `resolved` or `completed`):

```javascript
await firebase.firestore().collection('reports').doc(reportId).update({
  status: 'resolved',  // or 'completed'
  actionNotes: "Action taken description",  // Optional: what action was taken
  solutionDescription: "Final resolution details",  // ✅ REQUIRED: Use 'solutionDescription'
  resolvedAt: firebase.firestore.FieldValue.serverTimestamp(),
  updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
});
```

**Field Name: `solutionDescription`** (camelCase)
- ❌ NOT: `resolution`, `solution`, `solutionNote`
- ✅ USE: `solutionDescription`

---

## 🔧 Service Requests Collection (`service_requests`)

### When Taking Action on a Service Request

```javascript
await firebase.firestore().collection('service_requests').doc(requestId).update({
  status: 'actioned',  // or 'in-progress'
  actionNotes: "Your action notes here",  // ✅ REQUIRED: Use 'actionNotes'
  actionedAt: firebase.firestore.FieldValue.serverTimestamp(),
  updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
});
```

**Field Name: `actionNotes`** (plural, camelCase)

### When Resolving a Service Request

```javascript
await firebase.firestore().collection('service_requests').doc(requestId).update({
  status: 'resolved',  // or 'completed'
  actionNotes: "Action taken description",  // Optional
  solutionDescription: "Final resolution details",  // ✅ REQUIRED: Use 'solutionDescription'
  resolvedAt: firebase.firestore.FieldValue.serverTimestamp(),
  updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
});
```

**Field Name: `solutionDescription`** (camelCase)

---

## 📦 Borrowed Supplies Collection (`borrowed_supplies`)

### When Approving a Borrow Request

```javascript
await firebase.firestore().collection('borrowed_supplies').doc(borrowId).update({
  status: 'borrowed',  // or 'actioned'
  actionNotes: "Return by Dec 31, 2024",  // ✅ REQUIRED: Use 'actionNotes'
  approvedAt: firebase.firestore.FieldValue.serverTimestamp(),
  borrowedAt: firebase.firestore.FieldValue.serverTimestamp(),
});
```

**Field Name: `actionNotes`** (plural, camelCase)
- Example notes: "Please return by [date]", "Handle with care", "Return to Zone 1 office"

### When Rejecting a Borrow Request

```javascript
await firebase.firestore().collection('borrowed_supplies').doc(borrowId).update({
  status: 'rejected',
  rejectionReason: "Reason for rejection",  // ✅ REQUIRED: Use 'rejectionReason'
  rejectedAt: firebase.firestore.FieldValue.serverTimestamp(),
});
```

**Field Name: `rejectionReason`** (camelCase)

---

## 🔍 Lost Items Collection (`lost_items`)

### When Marking Lost Item as Found

```javascript
await firebase.firestore().collection('lost_items').doc(itemId).update({
  status: 'found',  // or 'returned'
  adminNotes: "Item claimed by owner",  // ✅ RECOMMENDED: Use 'adminNotes'
  foundByName: "John Doe",  // Name of person who found/returned it
  foundAt: firebase.firestore.FieldValue.serverTimestamp(),
  updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
});
```

**Field Name: `adminNotes`** (camelCase)
- Primary: `adminNotes`
- Fallback supported: `actionNotes` (will also work)

---

## 🎯 Quick Reference Table

| Collection | Action Type | Field Name | Type | Required |
|------------|-------------|------------|------|----------|
| `reports` | Take Action | `actionNotes` | string | Optional |
| `reports` | Resolve | `solutionDescription` | string | ✅ Yes |
| `service_requests` | Take Action | `actionNotes` | string | Optional |
| `service_requests` | Resolve | `solutionDescription` | string | ✅ Yes |
| `borrowed_supplies` | Approve | `actionNotes` | string | Optional |
| `borrowed_supplies` | Reject | `rejectionReason` | string | ✅ Yes |
| `lost_items` | Mark Found | `adminNotes` | string | Optional |

---

## ✨ Flutter App Fallback Support (New Update)

**Good News:** The Flutter app now supports multiple field name variations as fallbacks!

### Supported Fallback Variations:

**For Action Notes:**
- Primary: `actionNotes` ✅
- Fallback: `actionNote`
- Fallback: `action_notes`

**For Solution/Resolution:**
- Primary: `solutionDescription` ✅
- Fallback: `resolution`
- Fallback: `solution`

**For Lost Items Admin Notes:**
- Primary: `adminNotes` ✅
- Fallback: `adminNote`
- Fallback: `admin_notes`
- Fallback: `actionNotes`

**This means:** Even if your admin dashboard uses a different field name, the app will still display the notes!

### Example: All These Will Work

```javascript
// Option 1 (Recommended):
{ actionNotes: "Notes here" }

// Option 2 (Also works):
{ actionNote: "Notes here" }

// Option 3 (Also works):
{ action_notes: "Notes here" }

// Option 4 for resolution (Recommended):
{ solutionDescription: "Resolution details" }

// Option 5 for resolution (Also works):
{ resolution: "Resolution details" }
```

---

## 🚀 Complete Example: Report Workflow

### Step 1: Admin Takes Action

```javascript
// Admin clicks "Take Action" button
const actionNotes = prompt("Enter action notes:");

await db.collection('reports').doc(reportId).update({
  status: 'actioned',
  actionNotes: actionNotes,  // ✅ Correct field name
  actionedAt: firebase.firestore.FieldValue.serverTimestamp(),
  updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
});
```

**Result:** User sees blue box in app: "Admin Action Notes: [your notes]"

### Step 2: Admin Resolves Report

```javascript
// Admin clicks "Mark as Resolved" button
const solution = prompt("Enter resolution details:");

await db.collection('reports').doc(reportId).update({
  status: 'resolved',
  solutionDescription: solution,  // ✅ Correct field name
  resolvedAt: firebase.firestore.FieldValue.serverTimestamp(),
  updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
});
```

**Result:** User sees green box in app: "Admin Resolution: [your resolution]"

---

## 🎨 How It Appears in Flutter App

### Reports & Service Requests

When user views report/service details, they see:

```
┌─────────────────────────────────────┐
│ Report Details                      │
├─────────────────────────────────────┤
│ Category: Peace and Order           │
│ Location: Zone 4                    │
│ Status: Resolved                    │
│ Description: [user's description]   │
│                                     │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│                                     │
│ 👤 Admin Action Notes:              │
│ ┌─────────────────────────────────┐ │
│ │ [Blue background]               │ │
│ │ We have dispatched security     │ │
│ │ patrol to the area.             │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ✅ Admin Resolution:                │
│ ┌─────────────────────────────────┐ │
│ │ [Green background]              │ │
│ │ Security patrol deployed.       │ │
│ │ Area now monitored 24/7.        │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### Borrowed Items

```
┌─────────────────────────────────────┐
│ 📦 Tent              [BORROWED]     │
├─────────────────────────────────────┤
│ 👤 Admin Action Notes:              │
│ ┌─────────────────────────────────┐ │
│ │ Please return by Dec 31, 2024   │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Quantity: 2                         │
│ Purpose: Community event            │
└─────────────────────────────────────┘
```

---

## 🔧 Testing Your Implementation

### 1. Test Action Notes (Reports)

```javascript
// In your admin dashboard console:
await firebase.firestore().collection('reports').doc('YOUR_REPORT_ID').update({
  actionNotes: "Test action notes - checking if this appears in app",
  status: 'actioned'
});
```

**Expected:** Open Flutter app → My Reports → View Details → See blue box with your note

### 2. Test Resolution (Reports)

```javascript
await firebase.firestore().collection('reports').doc('YOUR_REPORT_ID').update({
  solutionDescription: "Test resolution - issue has been fixed",
  status: 'resolved'
});
```

**Expected:** Open Flutter app → My Reports → View Details → See green box with resolution

### 3. Test Service Request

```javascript
await firebase.firestore().collection('service_requests').doc('YOUR_REQUEST_ID').update({
  actionNotes: "Test service action notes",
  solutionDescription: "Service completed successfully",
  status: 'resolved'
});
```

**Expected:** Open Flutter app → Services tab → View Details → See both blue and green boxes

### 4. Test Borrowed Items

```javascript
await firebase.firestore().collection('borrowed_supplies').doc('YOUR_BORROW_ID').update({
  actionNotes: "Return by tomorrow",
  status: 'borrowed'
});
```

**Expected:** Open Flutter app → Borrowed Items tab → See action notes in card

---

## ❌ Common Mistakes to Avoid

### ❌ Wrong Field Names

```javascript
// DON'T DO THIS:
{
  actionNote: "...",         // Missing 's' - but will still work as fallback
  resolution: "...",         // Should be solutionDescription - but will work as fallback
  notes: "...",              // Too generic - WON'T work
  adminNote: "...",          // For lost items - will work as fallback
}
```

### ✅ Correct Field Names

```javascript
// DO THIS:
{
  actionNotes: "...",           // ✅ Perfect (plural)
  solutionDescription: "...",   // ✅ Perfect
  adminNotes: "...",            // ✅ Perfect (for lost items)
}
```

---

## 📞 Support

If action notes or resolution notes are not appearing in the Flutter app:

1. **Check Firestore**: Verify the field names match the recommended format
2. **Check Case**: Field names are case-sensitive (use camelCase)
3. **Check Status**: Notes only appear when status is appropriate:
   - `actionNotes`: Shows when status is `actioned`, `in-progress`, or `resolved`
   - `solutionDescription`: Shows only when status is `resolved` or `completed`
4. **Hot Restart App**: Ask users to restart the Flutter app after you make updates

---

## 🎉 Summary

**Primary Recommended Field Names:**
- Action Notes: **`actionNotes`** (plural)
- Resolution: **`solutionDescription`**
- Lost Items Notes: **`adminNotes`**
- Rejection Reason: **`rejectionReason`**

**Good News:**
- Flutter app now supports fallback variations
- Even if you use wrong field names, it will likely still work!
- But using recommended names ensures best compatibility

**Remember:**
- Use camelCase (JavaScript convention)
- Use descriptive field names
- Always use plural for notes fields (`actionNotes`, not `actionNote`)
- Test after implementation to verify it appears correctly in app

---

**Last Updated:** March 6, 2026
**Flutter App Version:** Compatible with all field name variations
**Admin Dashboard:** React Web Application
