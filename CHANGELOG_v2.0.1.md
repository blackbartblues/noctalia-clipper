# Clipper v2.0.1 - Bug Fix Release

**Release Date**: 2026-02-06

## 🐛 Bug Fixes

### ToDo Integration
- **Fixed QML warning when adding items to ToDo plugin**
  - Added missing `priority` field (default: "medium") to todo object
  - Added missing `details` field (empty string) to todo object
  - Resolves: "priority/details is undefined" warning in QML ListModel

### Documentation
- Added clarifying comment about cross-plugin integration
- Documented that Clipper → ToDo integration is allowed and not internal IPC

## 📝 Technical Details

**Problem:**
When adding items from Clipper to ToDo plugin, QML would show warnings:
```
WARN: priority is undefined. Adding an object with a undefined member does not create a role for it.
WARN: details is undefined. Adding an object with a undefined member does not create a role for it.
```

**Solution:**
Updated `addTodoWithText()` function to include all required fields that ToDo plugin expects:
```javascript
var newTodo = {
    id: Date.now(),
    text: trimmedText,
    completed: false,
    createdAt: new Date().toISOString(),
    pageId: pageId,
    priority: "medium",  // ✅ Added
    details: ""          // ✅ Added
};
```

## 🔄 Upgrade from v2.0.0

No action required - this is a drop-in replacement. Simply update and reload.

## 📊 Changes

- **Files changed**: 1 (Main.qml)
- **Lines changed**: +6 / -1
- **New features**: 0
- **Bug fixes**: 1

---

**Full changelog**: https://github.com/blackbartblues/noctalia-clipper/compare/v2.0.0...v2.0.1
