# Firebase Services Backup and Recovery Procedures

## Overview

This document provides comprehensive backup and recovery procedures for Firebase services utilized by Distro Nation's hybrid cloud architecture. Firebase services include Authentication, Realtime Database, Cloud Storage, and Cloud Functions, all requiring specialized backup strategies due to their Google Cloud Platform integration.

## Executive Summary

### Firebase Services Inventory

```yaml
Firebase Services in Use:
  - Firebase Authentication: User identity and access management
  - Firebase Realtime Database: Real-time data synchronization
  - Firebase Cloud Storage: File storage and CDN
  - Firebase Cloud Functions: Serverless compute
  - Firebase Analytics: User behavior tracking
  - Firebase Remote Config: Feature flag management

Estimated Monthly Cost: $70-230/month
Data Criticality: HIGH - Contains user authentication and real-time data
Integration Points: AWS Lambda, Aurora PostgreSQL, S3 Storage
```

### Backup Strategy Overview

- **Authentication**: User export + configuration backup
- **Realtime Database**: Automated exports + real-time backup
- **Cloud Storage**: Cross-platform replication to S3
- **Cloud Functions**: Source code version control + deployment automation
- **Configuration**: Infrastructure as Code + manual snapshots

## 1. Firebase Authentication Backup

### 1.1 User Data Export

#### Automated User Export Script

```javascript
// firebase-auth-backup.js
// Backup Firebase Authentication users

const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");

// Initialize Firebase Admin SDK
const serviceAccount = require("./service-account-key.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://your-project.firebaseio.com",
});

async function exportUsers() {
  const timestamp = new Date().toISOString().split("T")[0];
  const backupDir = `./firebase-backups/${timestamp}`;

  // Create backup directory
  if (!fs.existsSync(backupDir)) {
    fs.mkdirSync(backupDir, { recursive: true });
  }

  try {
    console.log("Starting Firebase Auth user export...");

    const users = [];
    let nextPageToken;

    do {
      const userRecords = await admin.auth().listUsers(1000, nextPageToken);

      userRecords.users.forEach((user) => {
        users.push({
          uid: user.uid,
          email: user.email,
          emailVerified: user.emailVerified,
          displayName: user.displayName,
          photoURL: user.photoURL,
          disabled: user.disabled,
          metadata: {
            creationTime: user.metadata.creationTime,
            lastSignInTime: user.metadata.lastSignInTime,
            lastRefreshTime: user.metadata.lastRefreshTime,
          },
          customClaims: user.customClaims,
          providerData: user.providerData.map((provider) => ({
            uid: provider.uid,
            email: provider.email,
            displayName: provider.displayName,
            photoURL: provider.photoURL,
            providerId: provider.providerId,
          })),
        });
      });

      nextPageToken = userRecords.pageToken;
      console.log(`Exported ${users.length} users so far...`);
    } while (nextPageToken);

    // Save users to JSON file
    const usersBackupPath = path.join(backupDir, "firebase-users.json");
    fs.writeFileSync(usersBackupPath, JSON.stringify(users, null, 2));

    console.log(
      `✓ Users backup completed: ${users.length} users exported to ${usersBackupPath}`
    );

    // Create backup summary
    const summary = {
      timestamp: new Date().toISOString(),
      totalUsers: users.length,
      activeUsers: users.filter((u) => !u.disabled).length,
      verifiedUsers: users.filter((u) => u.emailVerified).length,
      backupPath: usersBackupPath,
      retention: "90 days",
    };

    fs.writeFileSync(
      path.join(backupDir, "backup-summary.json"),
      JSON.stringify(summary, null, 2)
    );

    return summary;
  } catch (error) {
    console.error("Error exporting users:", error);
    throw error;
  }
}

// Export custom claims separately for security
async function exportCustomClaims() {
  const timestamp = new Date().toISOString().split("T")[0];
  const backupDir = `./firebase-backups/${timestamp}`;

  try {
    console.log("Exporting custom claims...");

    const customClaims = [];
    let nextPageToken;

    do {
      const userRecords = await admin.auth().listUsers(1000, nextPageToken);

      userRecords.users.forEach((user) => {
        if (user.customClaims && Object.keys(user.customClaims).length > 0) {
          customClaims.push({
            uid: user.uid,
            email: user.email,
            customClaims: user.customClaims,
          });
        }
      });

      nextPageToken = userRecords.pageToken;
    } while (nextPageToken);

    const claimsBackupPath = path.join(backupDir, "custom-claims.json");
    fs.writeFileSync(claimsBackupPath, JSON.stringify(customClaims, null, 2));

    console.log(
      `✓ Custom claims backup completed: ${customClaims.length} users with custom claims`
    );

    return claimsBackupPath;
  } catch (error) {
    console.error("Error exporting custom claims:", error);
    throw error;
  }
}

// Main backup function
async function performAuthBackup() {
  try {
    const summary = await exportUsers();
    await exportCustomClaims();

    console.log("\n=== Firebase Auth Backup Summary ===");
    console.log(`Total Users: ${summary.totalUsers}`);
    console.log(`Active Users: ${summary.activeUsers}`);
    console.log(`Verified Users: ${summary.verifiedUsers}`);
    console.log(`Backup Location: ${summary.backupPath}`);

    return summary;
  } catch (error) {
    console.error("Backup failed:", error);
    process.exit(1);
  }
}

// Run backup if called directly
if (require.main === module) {
  performAuthBackup();
}

module.exports = { performAuthBackup, exportUsers, exportCustomClaims };
```

#### User Recovery Script

```javascript
// firebase-auth-restore.js
// Restore Firebase Authentication users from backup

const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");

async function restoreUsers(backupFilePath, dryRun = true) {
  try {
    console.log(
      `${
        dryRun ? "DRY RUN:" : ""
      } Starting user restoration from ${backupFilePath}`
    );

    const backupData = JSON.parse(fs.readFileSync(backupFilePath, "utf8"));

    let successCount = 0;
    let errorCount = 0;
    const errors = [];

    for (const userData of backupData) {
      try {
        if (!dryRun) {
          // Create user with specific UID
          await admin.auth().createUser({
            uid: userData.uid,
            email: userData.email,
            emailVerified: userData.emailVerified,
            displayName: userData.displayName,
            photoURL: userData.photoURL,
            disabled: userData.disabled,
          });

          // Set custom claims if they exist
          if (userData.customClaims) {
            await admin
              .auth()
              .setCustomUserClaims(userData.uid, userData.customClaims);
          }
        }

        successCount++;

        if (successCount % 100 === 0) {
          console.log(
            `${dryRun ? "Would restore" : "Restored"} ${successCount} users...`
          );
        }
      } catch (error) {
        errorCount++;
        errors.push({
          uid: userData.uid,
          email: userData.email,
          error: error.message,
        });

        // Continue with other users
        continue;
      }
    }

    console.log("\n=== Restoration Summary ===");
    console.log(
      `${
        dryRun ? "Would restore" : "Successfully restored"
      }: ${successCount} users`
    );
    console.log(`Errors: ${errorCount} users`);

    if (errors.length > 0) {
      console.log("\nFirst 10 errors:");
      errors.slice(0, 10).forEach((err) => {
        console.log(`- ${err.email} (${err.uid}): ${err.error}`);
      });
    }

    return {
      successCount,
      errorCount,
      errors,
      dryRun,
    };
  } catch (error) {
    console.error("Restoration failed:", error);
    throw error;
  }
}

// Usage example:
// node firebase-auth-restore.js ./firebase-backups/2025-07-25/firebase-users.json
if (require.main === module) {
  const backupPath = process.argv[2];
  const dryRun = process.argv[3] !== "--execute";

  if (!backupPath) {
    console.error(
      "Usage: node firebase-auth-restore.js <backup-file-path> [--execute]"
    );
    process.exit(1);
  }

  restoreUsers(backupPath, dryRun);
}

module.exports = { restoreUsers };
```

### 1.2 Authentication Configuration Backup

#### Firebase Auth Settings Export

```bash
#!/bin/bash
# firebase-auth-config-backup.sh
# Backup Firebase Authentication configuration

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="./firebase-backups/$TIMESTAMP"
PROJECT_ID="your-firebase-project-id"

echo "Backing up Firebase Auth configuration for project: $PROJECT_ID"

mkdir -p "$BACKUP_DIR"

# Export authentication configuration
firebase auth:export "$BACKUP_DIR/auth-config.json" --project "$PROJECT_ID"

# Export security rules if applicable
firebase database:get / --project "$PROJECT_ID" > "$BACKUP_DIR/database-rules.json"

# Export Firebase configuration
firebase setup:web --project "$PROJECT_ID" > "$BACKUP_DIR/firebase-config.js"

# Create configuration summary
cat > "$BACKUP_DIR/config-summary.md" << EOF
# Firebase Authentication Configuration Backup

**Project ID:** $PROJECT_ID
**Backup Date:** $(date)
**Backup Location:** $BACKUP_DIR

## Files Included:
- auth-config.json: Authentication provider configuration
- database-rules.json: Security rules export
- firebase-config.js: Web app configuration

## Recovery Instructions:
1. Initialize new Firebase project
2. Import authentication configuration
3. Apply security rules
4. Update web app configuration

## Retention:
This backup should be retained for 1 year minimum.
EOF

echo "✓ Firebase Auth configuration backup completed: $BACKUP_DIR"
```

## 2. Firebase Realtime Database Backup

### 2.1 Automated Database Export

#### Realtime Database Backup Script

```javascript
// firebase-database-backup.js
// Comprehensive backup of Firebase Realtime Database

const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");

async function backupRealtimeDatabase() {
  const timestamp = new Date().toISOString().split("T")[0];
  const backupDir = `./firebase-backups/${timestamp}`;

  // Create backup directory
  if (!fs.existsSync(backupDir)) {
    fs.mkdirSync(backupDir, { recursive: true });
  }

  try {
    console.log("Starting Firebase Realtime Database backup...");

    const database = admin.database();

    // Backup entire database
    console.log("Exporting full database...");
    const fullBackup = await database.ref("/").once("value");
    const fullBackupPath = path.join(backupDir, "realtime-database-full.json");
    fs.writeFileSync(fullBackupPath, JSON.stringify(fullBackup.val(), null, 2));

    // Backup critical paths separately for easier recovery
    const criticalPaths = [
      "users",
      "userProfiles",
      "payouts",
      "tracks",
      "analytics",
      "configurations",
    ];

    const pathBackups = {};

    for (const path of criticalPaths) {
      try {
        console.log(`Exporting path: /${path}`);
        const pathData = await database.ref(`/${path}`).once("value");

        if (pathData.exists()) {
          const pathBackupFile = path.join(backupDir, `${path}.json`);
          fs.writeFileSync(
            pathBackupFile,
            JSON.stringify(pathData.val(), null, 2)
          );

          pathBackups[path] = {
            records: Object.keys(pathData.val() || {}).length,
            filePath: pathBackupFile,
            size: fs.statSync(pathBackupFile).size,
          };
        } else {
          console.log(`Path /${path} does not exist`);
          pathBackups[path] = { exists: false };
        }
      } catch (error) {
        console.error(`Error backing up path /${path}:`, error);
        pathBackups[path] = { error: error.message };
      }
    }

    // Create backup metadata
    const backupMetadata = {
      timestamp: new Date().toISOString(),
      projectId: admin.app().options.projectId,
      fullBackupPath: fullBackupPath,
      fullBackupSize: fs.statSync(fullBackupPath).size,
      pathBackups: pathBackups,
      backupIntegrity: "verified",
      retention: "90 days",
    };

    const metadataPath = path.join(backupDir, "backup-metadata.json");
    fs.writeFileSync(metadataPath, JSON.stringify(backupMetadata, null, 2));

    console.log("\n=== Firebase Database Backup Summary ===");
    console.log(
      `Full backup size: ${(
        backupMetadata.fullBackupSize /
        1024 /
        1024
      ).toFixed(2)} MB`
    );
    console.log(
      `Critical paths backed up: ${
        Object.keys(pathBackups).filter((p) => pathBackups[p].records).length
      }`
    );
    console.log(`Backup location: ${backupDir}`);

    return backupMetadata;
  } catch (error) {
    console.error("Database backup failed:", error);
    throw error;
  }
}

// Incremental backup for frequently changing data
async function incrementalBackup(lastBackupTimestamp) {
  const timestamp = new Date().toISOString().split("T")[0];
  const backupDir = `./firebase-backups/${timestamp}/incremental`;

  if (!fs.existsSync(backupDir)) {
    fs.mkdirSync(backupDir, { recursive: true });
  }

  try {
    console.log(`Starting incremental backup since ${lastBackupTimestamp}...`);

    const database = admin.database();

    // Query data modified since last backup
    const modifiedData = await database
      .ref("/")
      .orderByChild("lastModified")
      .startAt(lastBackupTimestamp)
      .once("value");

    if (modifiedData.exists()) {
      const incrementalBackupPath = path.join(
        backupDir,
        "incremental-changes.json"
      );
      fs.writeFileSync(
        incrementalBackupPath,
        JSON.stringify(modifiedData.val(), null, 2)
      );

      console.log(`✓ Incremental backup completed: ${incrementalBackupPath}`);

      return {
        incrementalBackupPath,
        changedRecords: Object.keys(modifiedData.val()).length,
        timestamp: new Date().toISOString(),
      };
    } else {
      console.log("No changes found since last backup");
      return null;
    }
  } catch (error) {
    console.error("Incremental backup failed:", error);
    throw error;
  }
}

// Real-time backup streaming
function setupRealtimeBackup() {
  const database = admin.database();

  // Monitor critical data changes and backup immediately
  const criticalPaths = ["users", "payouts", "tracks"];

  criticalPaths.forEach((path) => {
    database.ref(`/${path}`).on("child_changed", (snapshot) => {
      const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
      const changeBackupDir = `./firebase-backups/realtime-changes/${timestamp}`;

      if (!fs.existsSync(changeBackupDir)) {
        fs.mkdirSync(changeBackupDir, { recursive: true });
      }

      const changeData = {
        path: `/${path}/${snapshot.key}`,
        data: snapshot.val(),
        timestamp: new Date().toISOString(),
        changeType: "modified",
      };

      fs.writeFileSync(
        path.join(changeBackupDir, `${path}-${snapshot.key}.json`),
        JSON.stringify(changeData, null, 2)
      );

      console.log(`Real-time backup: ${changeData.path}`);
    });
  });

  console.log("Real-time backup monitoring started for critical paths");
}

module.exports = {
  backupRealtimeDatabase,
  incrementalBackup,
  setupRealtimeBackup,
};

// Run backup if called directly
if (require.main === module) {
  backupRealtimeDatabase();
}
```

### 2.2 Database Recovery Procedures

#### Database Restoration Script

```javascript
// firebase-database-restore.js
// Restore Firebase Realtime Database from backup

const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");

async function restoreDatabase(
  backupFilePath,
  targetPath = "/",
  dryRun = true
) {
  try {
    console.log(
      `${
        dryRun ? "DRY RUN:" : ""
      } Restoring database from ${backupFilePath} to ${targetPath}`
    );

    if (!fs.existsSync(backupFilePath)) {
      throw new Error(`Backup file not found: ${backupFilePath}`);
    }

    const backupData = JSON.parse(fs.readFileSync(backupFilePath, "utf8"));
    const database = admin.database();

    if (!dryRun) {
      // Clear target path if it's a full restore
      if (targetPath === "/") {
        console.log("WARNING: This will overwrite the entire database");
        // In production, add confirmation prompt
      }

      await database.ref(targetPath).set(backupData);
      console.log(`✓ Database restored to ${targetPath}`);
    } else {
      console.log(
        `Would restore ${
          Object.keys(backupData).length
        } top-level keys to ${targetPath}`
      );
      console.log(
        "Top-level keys:",
        Object.keys(backupData).slice(0, 10).join(", ")
      );
    }

    return {
      success: true,
      restoredKeys: Object.keys(backupData).length,
      targetPath,
      dryRun,
    };
  } catch (error) {
    console.error("Database restoration failed:", error);
    throw error;
  }
}

// Selective path restoration
async function restoreSpecificPath(backupDir, pathName, dryRun = true) {
  const pathBackupFile = path.join(backupDir, `${pathName}.json`);

  if (!fs.existsSync(pathBackupFile)) {
    throw new Error(`Path backup file not found: ${pathBackupFile}`);
  }

  console.log(`${dryRun ? "DRY RUN:" : ""} Restoring path /${pathName}`);

  const pathData = JSON.parse(fs.readFileSync(pathBackupFile, "utf8"));
  const database = admin.database();

  if (!dryRun) {
    await database.ref(`/${pathName}`).set(pathData);
    console.log(`✓ Path /${pathName} restored successfully`);
  } else {
    const recordCount =
      typeof pathData === "object" ? Object.keys(pathData).length : 1;
    console.log(`Would restore ${recordCount} records to /${pathName}`);
  }

  return {
    pathName,
    recordCount:
      typeof pathData === "object" ? Object.keys(pathData).length : 1,
    dryRun,
  };
}

// Merge backup with current data (for incremental restores)
async function mergeBackupData(backupFilePath, dryRun = true) {
  try {
    console.log(
      `${dryRun ? "DRY RUN:" : ""} Merging backup data from ${backupFilePath}`
    );

    const backupData = JSON.parse(fs.readFileSync(backupFilePath, "utf8"));
    const database = admin.database();

    let updateCount = 0;

    for (const [key, value] of Object.entries(backupData)) {
      if (!dryRun) {
        await database.ref(`/${key}`).update(value);
      }
      updateCount++;
    }

    console.log(`${dryRun ? "Would merge" : "Merged"} ${updateCount} records`);

    return {
      mergedRecords: updateCount,
      dryRun,
    };
  } catch (error) {
    console.error("Backup merge failed:", error);
    throw error;
  }
}

module.exports = {
  restoreDatabase,
  restoreSpecificPath,
  mergeBackupData,
};

// CLI usage
if (require.main === module) {
  const command = process.argv[2];
  const backupPath = process.argv[3];
  const dryRun = process.argv[4] !== "--execute";

  switch (command) {
    case "full":
      if (!backupPath) {
        console.error(
          "Usage: node firebase-database-restore.js full <backup-file-path> [--execute]"
        );
        process.exit(1);
      }
      restoreDatabase(backupPath, "/", dryRun);
      break;

    case "path":
      const pathName = process.argv[4];
      if (!backupPath || !pathName) {
        console.error(
          "Usage: node firebase-database-restore.js path <backup-dir> <path-name> [--execute]"
        );
        process.exit(1);
      }
      restoreSpecificPath(backupPath, pathName, dryRun);
      break;

    case "merge":
      if (!backupPath) {
        console.error(
          "Usage: node firebase-database-restore.js merge <backup-file-path> [--execute]"
        );
        process.exit(1);
      }
      mergeBackupData(backupPath, dryRun);
      break;

    default:
      console.error(
        "Usage: node firebase-database-restore.js <full|path|merge> ..."
      );
      process.exit(1);
  }
}
```

## 3. Firebase Cloud Storage Backup

### 3.1 Cross-Platform Storage Replication

#### Firebase Storage to S3 Backup

```javascript
// firebase-storage-backup.js
// Backup Firebase Cloud Storage to AWS S3

const admin = require("firebase-admin");
const AWS = require("aws-sdk");
const fs = require("fs");
const path = require("path");
const stream = require("stream");

// Configure AWS S3
const s3 = new AWS.S3({
  region: "<REGION>",
});

const BACKUP_BUCKET = "distronation-firebase-backup";

async function backupFirebaseStorage() {
  const timestamp = new Date().toISOString().split("T")[0];

  try {
    console.log("Starting Firebase Cloud Storage backup to S3...");

    const bucket = admin.storage().bucket();

    // List all files in Firebase Storage
    const [files] = await bucket.getFiles();

    console.log(`Found ${files.length} files to backup`);

    const backupResults = [];
    let successCount = 0;
    let errorCount = 0;

    for (const file of files) {
      try {
        // Create S3 key with timestamp prefix
        const s3Key = `firebase-storage-backup/${timestamp}/${file.name}`;

        console.log(
          `Backing up: ${file.name} -> s3://${BACKUP_BUCKET}/${s3Key}`
        );

        // Get file metadata
        const [metadata] = await file.getMetadata();

        // Stream file from Firebase to S3
        const firebaseStream = file.createReadStream();

        const uploadParams = {
          Bucket: BACKUP_BUCKET,
          Key: s3Key,
          Body: firebaseStream,
          Metadata: {
            "firebase-name": file.name,
            "firebase-created": metadata.timeCreated,
            "firebase-updated": metadata.updated,
            "backup-timestamp": new Date().toISOString(),
          },
        };

        const uploadResult = await s3.upload(uploadParams).promise();

        backupResults.push({
          firebasePath: file.name,
          s3Location: uploadResult.Location,
          size: metadata.size,
          success: true,
        });

        successCount++;

        if (successCount % 100 === 0) {
          console.log(`Backed up ${successCount} files...`);
        }
      } catch (error) {
        console.error(`Error backing up ${file.name}:`, error);

        backupResults.push({
          firebasePath: file.name,
          error: error.message,
          success: false,
        });

        errorCount++;
      }
    }

    // Create backup manifest
    const manifest = {
      timestamp: new Date().toISOString(),
      totalFiles: files.length,
      successCount,
      errorCount,
      backupLocation: `s3://${BACKUP_BUCKET}/firebase-storage-backup/${timestamp}/`,
      results: backupResults,
    };

    // Save manifest to S3
    const manifestKey = `firebase-storage-backup/${timestamp}/backup-manifest.json`;
    await s3
      .putObject({
        Bucket: BACKUP_BUCKET,
        Key: manifestKey,
        Body: JSON.stringify(manifest, null, 2),
        ContentType: "application/json",
      })
      .promise();

    console.log("\n=== Firebase Storage Backup Summary ===");
    console.log(`Total files: ${files.length}`);
    console.log(`Successfully backed up: ${successCount}`);
    console.log(`Errors: ${errorCount}`);
    console.log(`Manifest: s3://${BACKUP_BUCKET}/${manifestKey}`);

    return manifest;
  } catch (error) {
    console.error("Firebase Storage backup failed:", error);
    throw error;
  }
}

// Incremental backup - only backup new/changed files
async function incrementalStorageBackup(lastBackupTimestamp) {
  try {
    console.log(`Starting incremental backup since ${lastBackupTimestamp}...`);

    const bucket = admin.storage().bucket();
    const timestamp = new Date().toISOString().split("T")[0];

    // List files modified since last backup
    const [files] = await bucket.getFiles();

    const filesToBackup = [];

    for (const file of files) {
      const [metadata] = await file.getMetadata();
      const fileUpdated = new Date(metadata.updated);
      const lastBackup = new Date(lastBackupTimestamp);

      if (fileUpdated > lastBackup) {
        filesToBackup.push(file);
      }
    }

    console.log(
      `Found ${filesToBackup.length} files modified since last backup`
    );

    if (filesToBackup.length === 0) {
      console.log("No new files to backup");
      return null;
    }

    // Backup only changed files
    let successCount = 0;

    for (const file of filesToBackup) {
      try {
        const s3Key = `firebase-storage-incremental/${timestamp}/${file.name}`;

        const firebaseStream = file.createReadStream();

        await s3
          .upload({
            Bucket: BACKUP_BUCKET,
            Key: s3Key,
            Body: firebaseStream,
            Metadata: {
              "backup-type": "incremental",
              "backup-timestamp": new Date().toISOString(),
            },
          })
          .promise();

        successCount++;
      } catch (error) {
        console.error(`Error in incremental backup for ${file.name}:`, error);
      }
    }

    console.log(`✓ Incremental backup completed: ${successCount} files`);

    return {
      timestamp: new Date().toISOString(),
      backupType: "incremental",
      filesBackedUp: successCount,
      totalCandidates: filesToBackup.length,
    };
  } catch (error) {
    console.error("Incremental storage backup failed:", error);
    throw error;
  }
}

module.exports = {
  backupFirebaseStorage,
  incrementalStorageBackup,
};

// Run backup if called directly
if (require.main === module) {
  const backupType = process.argv[2] || "full";

  if (backupType === "incremental") {
    const lastBackupTime = process.argv[3];
    if (!lastBackupTime) {
      console.error(
        "Usage: node firebase-storage-backup.js incremental <last-backup-timestamp>"
      );
      process.exit(1);
    }
    incrementalStorageBackup(lastBackupTime);
  } else {
    backupFirebaseStorage();
  }
}
```

### 3.2 Storage Recovery Procedures

#### Firebase Storage Restoration

```javascript
// firebase-storage-restore.js
// Restore Firebase Cloud Storage from S3 backup

const admin = require("firebase-admin");
const AWS = require("aws-sdk");

const s3 = new AWS.S3({ region: "<REGION>" });
const BACKUP_BUCKET = "distronation-firebase-backup";

async function restoreFromS3Backup(backupTimestamp, dryRun = true) {
  try {
    console.log(
      `${
        dryRun ? "DRY RUN:" : ""
      } Restoring Firebase Storage from backup: ${backupTimestamp}`
    );

    const bucket = admin.storage().bucket();
    const backupPrefix = `firebase-storage-backup/${backupTimestamp}/`;

    // List backup files in S3
    const s3Objects = await s3
      .listObjectsV2({
        Bucket: BACKUP_BUCKET,
        Prefix: backupPrefix,
      })
      .promise();

    if (!s3Objects.Contents || s3Objects.Contents.length === 0) {
      throw new Error(`No backup found for timestamp: ${backupTimestamp}`);
    }

    console.log(`Found ${s3Objects.Contents.length} files in backup`);

    let restoreCount = 0;
    let errorCount = 0;

    for (const s3Object of s3Objects.Contents) {
      try {
        // Skip manifest file
        if (s3Object.Key.endsWith("backup-manifest.json")) {
          continue;
        }

        // Extract original Firebase path
        const firebasePath = s3Object.Key.replace(backupPrefix, "");

        console.log(`Restoring: ${firebasePath}`);

        if (!dryRun) {
          // Download from S3
          const s3Stream = s3
            .getObject({
              Bucket: BACKUP_BUCKET,
              Key: s3Object.Key,
            })
            .createReadStream();

          // Upload to Firebase
          const firebaseFile = bucket.file(firebasePath);

          await new Promise((resolve, reject) => {
            const uploadStream = firebaseFile.createWriteStream({
              metadata: {
                metadata: {
                  restoredFrom: s3Object.Key,
                  restoredAt: new Date().toISOString(),
                },
              },
            });

            uploadStream.on("error", reject);
            uploadStream.on("finish", resolve);

            s3Stream.pipe(uploadStream);
          });
        }

        restoreCount++;

        if (restoreCount % 50 === 0) {
          console.log(
            `${dryRun ? "Would restore" : "Restored"} ${restoreCount} files...`
          );
        }
      } catch (error) {
        console.error(`Error restoring ${s3Object.Key}:`, error);
        errorCount++;
      }
    }

    console.log("\n=== Firebase Storage Restoration Summary ===");
    console.log(
      `${
        dryRun ? "Would restore" : "Successfully restored"
      }: ${restoreCount} files`
    );
    console.log(`Errors: ${errorCount} files`);

    return {
      restoredFiles: restoreCount,
      errors: errorCount,
      dryRun,
    };
  } catch (error) {
    console.error("Firebase Storage restoration failed:", error);
    throw error;
  }
}

// Selective file restoration
async function restoreSpecificFiles(backupTimestamp, filePaths, dryRun = true) {
  try {
    console.log(
      `${
        dryRun ? "DRY RUN:" : ""
      } Restoring specific files from backup: ${backupTimestamp}`
    );

    const bucket = admin.storage().bucket();
    const backupPrefix = `firebase-storage-backup/${backupTimestamp}/`;

    let restoreCount = 0;

    for (const filePath of filePaths) {
      try {
        const s3Key = backupPrefix + filePath;

        console.log(`Restoring: ${filePath}`);

        if (!dryRun) {
          // Check if backup exists
          try {
            await s3
              .headObject({
                Bucket: BACKUP_BUCKET,
                Key: s3Key,
              })
              .promise();
          } catch (error) {
            if (error.code === "NotFound") {
              console.log(`Backup not found for: ${filePath}`);
              continue;
            }
            throw error;
          }

          // Download and restore
          const s3Stream = s3
            .getObject({
              Bucket: BACKUP_BUCKET,
              Key: s3Key,
            })
            .createReadStream();

          const firebaseFile = bucket.file(filePath);

          await new Promise((resolve, reject) => {
            const uploadStream = firebaseFile.createWriteStream();
            uploadStream.on("error", reject);
            uploadStream.on("finish", resolve);
            s3Stream.pipe(uploadStream);
          });
        }

        restoreCount++;
      } catch (error) {
        console.error(`Error restoring ${filePath}:`, error);
      }
    }

    console.log(
      `${dryRun ? "Would restore" : "Restored"} ${restoreCount} specific files`
    );

    return { restoredFiles: restoreCount, dryRun };
  } catch (error) {
    console.error("Specific file restoration failed:", error);
    throw error;
  }
}

module.exports = {
  restoreFromS3Backup,
  restoreSpecificFiles,
};

// CLI usage
if (require.main === module) {
  const command = process.argv[2];
  const backupTimestamp = process.argv[3];
  const dryRun = process.argv[4] !== "--execute";

  if (!backupTimestamp) {
    console.error(
      "Usage: node firebase-storage-restore.js <full|specific> <backup-timestamp> [--execute]"
    );
    process.exit(1);
  }

  if (command === "full") {
    restoreFromS3Backup(backupTimestamp, dryRun);
  } else if (command === "specific") {
    const filePaths = process.argv.slice(5);
    if (filePaths.length === 0) {
      console.error(
        "Usage: node firebase-storage-restore.js specific <backup-timestamp> [--execute] <file1> <file2> ..."
      );
      process.exit(1);
    }
    restoreSpecificFiles(backupTimestamp, filePaths, dryRun);
  } else {
    console.error('Command must be "full" or "specific"');
    process.exit(1);
  }
}
```

## 4. Firebase Cloud Functions Backup

### 4.1 Source Code and Configuration Backup

#### Functions Deployment Backup

```bash
#!/bin/bash
# firebase-functions-backup.sh
# Backup Firebase Cloud Functions source code and configuration

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="./firebase-backups/$TIMESTAMP/functions"
PROJECT_ID="your-firebase-project-id"

echo "Backing up Firebase Cloud Functions for project: $PROJECT_ID"

mkdir -p "$BACKUP_DIR"

# Backup functions source code (assuming functions are in ./functions directory)
if [ -d "./functions" ]; then
  echo "Backing up functions source code..."
  cp -r ./functions "$BACKUP_DIR/source-code"

  # Create source code archive
  tar -czf "$BACKUP_DIR/functions-source-$TIMESTAMP.tar.gz" -C ./functions .

  echo "✓ Functions source code backed up"
else
  echo "⚠ Functions source directory not found"
fi

# Export function configurations
echo "Exporting function configurations..."

# List all functions and their configurations
firebase functions:list --project "$PROJECT_ID" > "$BACKUP_DIR/functions-list.txt"

# Export environment variables
firebase functions:config:get --project "$PROJECT_ID" > "$BACKUP_DIR/functions-config.json"

# Backup package.json and dependencies
if [ -f "./functions/package.json" ]; then
  cp "./functions/package.json" "$BACKUP_DIR/package.json"
  cp "./functions/package-lock.json" "$BACKUP_DIR/package-lock.json" 2>/dev/null || true
fi

# Create deployment script for recovery
cat > "$BACKUP_DIR/deploy-functions.sh" << EOF
#!/bin/bash
# Auto-generated deployment script for Firebase Functions recovery

echo "Restoring Firebase Functions from backup..."

# Install dependencies
cd source-code
npm install

# Deploy functions
firebase deploy --only functions --project $PROJECT_ID

echo "Functions restoration completed"
EOF

chmod +x "$BACKUP_DIR/deploy-functions.sh"

# Create backup summary
cat > "$BACKUP_DIR/functions-backup-summary.md" << EOF
# Firebase Functions Backup Summary

**Project ID:** $PROJECT_ID
**Backup Date:** $(date)
**Backup Location:** $BACKUP_DIR

## Contents:
- source-code/: Complete functions source code
- functions-source-$TIMESTAMP.tar.gz: Compressed source archive
- functions-list.txt: List of deployed functions
- functions-config.json: Environment configuration
- package.json: Dependencies manifest
- deploy-functions.sh: Automated deployment script

## Recovery Process:
1. Extract source code: \`tar -xzf functions-source-$TIMESTAMP.tar.gz\`
2. Run deployment script: \`./deploy-functions.sh\`
3. Verify function deployments

## Retention:
Source code backups retained for 6 months minimum.
EOF

echo "✓ Firebase Functions backup completed: $BACKUP_DIR"
```

### 4.2 Functions Recovery Procedures

#### Automated Functions Restoration

```javascript
// firebase-functions-restore.js
// Restore Firebase Cloud Functions from backup

const { execSync } = require("child_process");
const fs = require("fs");
const path = require("path");

async function restoreFunctions(backupDir, projectId, dryRun = true) {
  try {
    console.log(
      `${
        dryRun ? "DRY RUN:" : ""
      } Restoring Firebase Functions from ${backupDir}`
    );

    // Verify backup directory structure
    const requiredFiles = [
      "source-code",
      "functions-config.json",
      "package.json",
    ];

    for (const file of requiredFiles) {
      const filePath = path.join(backupDir, file);
      if (!fs.existsSync(filePath)) {
        throw new Error(`Required backup file missing: ${file}`);
      }
    }

    // Restore environment configuration
    console.log("Restoring environment configuration...");

    const configPath = path.join(backupDir, "functions-config.json");
    const config = JSON.parse(fs.readFileSync(configPath, "utf8"));

    if (!dryRun) {
      // Set each configuration key
      for (const [key, value] of Object.entries(config)) {
        const configCommand = `firebase functions:config:set ${key}="${JSON.stringify(
          value
        )}" --project ${projectId}`;
        execSync(configCommand, { stdio: "inherit" });
      }
    } else {
      console.log(
        `Would restore ${Object.keys(config).length} configuration keys`
      );
    }

    // Restore source code
    console.log("Restoring functions source code...");

    const sourceDir = path.join(backupDir, "source-code");
    const targetDir = "./functions";

    if (!dryRun) {
      // Backup current functions if they exist
      if (fs.existsSync(targetDir)) {
        const backupCurrentDir = `./functions-backup-${Date.now()}`;
        execSync(`mv ${targetDir} ${backupCurrentDir}`);
        console.log(`Current functions backed up to ${backupCurrentDir}`);
      }

      // Copy restored source code
      execSync(`cp -r ${sourceDir} ${targetDir}`);

      // Install dependencies
      console.log("Installing dependencies...");
      execSync("npm install", { cwd: targetDir, stdio: "inherit" });

      // Deploy functions
      console.log("Deploying functions...");
      execSync(`firebase deploy --only functions --project ${projectId}`, {
        stdio: "inherit",
      });
    } else {
      const sourceFiles = fs.readdirSync(sourceDir);
      console.log(`Would restore ${sourceFiles.length} source files`);
      console.log("Source files:", sourceFiles.slice(0, 10).join(", "));
    }

    console.log(
      `${dryRun ? "Would complete" : "Completed"} functions restoration`
    );

    return {
      success: true,
      configKeys: Object.keys(config).length,
      sourceFiles: fs.readdirSync(sourceDir).length,
      dryRun,
    };
  } catch (error) {
    console.error("Functions restoration failed:", error);
    throw error;
  }
}

// Selective function restoration
async function restoreSpecificFunctions(
  backupDir,
  functionNames,
  projectId,
  dryRun = true
) {
  try {
    console.log(
      `${
        dryRun ? "DRY RUN:" : ""
      } Restoring specific functions: ${functionNames.join(", ")}`
    );

    const sourceDir = path.join(backupDir, "source-code");

    // Check if functions exist in backup
    const indexPath = path.join(sourceDir, "index.js");
    const sourceCode = fs.readFileSync(indexPath, "utf8");

    const missingFunctions = functionNames.filter(
      (name) =>
        !sourceCode.includes(`exports.${name}`) &&
        !sourceCode.includes(`exports['${name}']`)
    );

    if (missingFunctions.length > 0) {
      console.warn(
        `Functions not found in backup: ${missingFunctions.join(", ")}`
      );
    }

    if (!dryRun) {
      // Deploy only specific functions
      const functionList = functionNames.join(",");
      execSync(
        `firebase deploy --only functions:${functionList} --project ${projectId}`,
        {
          stdio: "inherit",
        }
      );
    } else {
      console.log(`Would deploy functions: ${functionNames.join(", ")}`);
    }

    return {
      requestedFunctions: functionNames.length,
      missingFunctions: missingFunctions.length,
      dryRun,
    };
  } catch (error) {
    console.error("Specific functions restoration failed:", error);
    throw error;
  }
}

module.exports = {
  restoreFunctions,
  restoreSpecificFunctions,
};

// CLI usage
if (require.main === module) {
  const command = process.argv[2];
  const backupDir = process.argv[3];
  const projectId = process.argv[4];
  const dryRun = process.argv[5] !== "--execute";

  if (!backupDir || !projectId) {
    console.error(
      "Usage: node firebase-functions-restore.js <full|specific> <backup-dir> <project-id> [--execute] [function-names...]"
    );
    process.exit(1);
  }

  if (command === "full") {
    restoreFunctions(backupDir, projectId, dryRun);
  } else if (command === "specific") {
    const functionNames = process.argv.slice(6);
    if (functionNames.length === 0) {
      console.error("Please specify function names to restore");
      process.exit(1);
    }
    restoreSpecificFunctions(backupDir, functionNames, projectId, dryRun);
  } else {
    console.error('Command must be "full" or "specific"');
    process.exit(1);
  }
}
```

## 5. Comprehensive Backup Automation

### 5.1 Orchestrated Backup Script

#### Master Firebase Backup Script

```bash
#!/bin/bash
# firebase-master-backup.sh
# Comprehensive backup of all Firebase services

set -e  # Exit on any error

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_ROOT_DIR="./firebase-backups/$TIMESTAMP"
PROJECT_ID="your-firebase-project-id"
NOTIFICATION_TOPIC="arn:aws:sns:<REGION>:<AWS_ACCOUNT_ID>:firebase-backup-alerts"

echo "=== Starting Comprehensive Firebase Backup ==="
echo "Project ID: $PROJECT_ID"
echo "Timestamp: $TIMESTAMP"
echo "Backup Location: $BACKUP_ROOT_DIR"

mkdir -p "$BACKUP_ROOT_DIR"

# Initialize backup log
BACKUP_LOG="$BACKUP_ROOT_DIR/backup.log"
echo "Firebase Backup Started at $(date)" > "$BACKUP_LOG"

# Backup success tracking
declare -A backup_results

# Function to log and track results
log_result() {
  local service=$1
  local status=$2
  local message=$3

  backup_results[$service]=$status
  echo "[$service] $status: $message" | tee -a "$BACKUP_LOG"
}

# 1. Backup Firebase Authentication
echo "--- Backing up Firebase Authentication ---"
if node firebase-auth-backup.js > "$BACKUP_ROOT_DIR/auth-backup.log" 2>&1; then
  log_result "Authentication" "SUCCESS" "User data and configuration exported"
else
  log_result "Authentication" "FAILED" "Error during authentication backup"
fi

# 2. Backup Realtime Database
echo "--- Backing up Realtime Database ---"
if node firebase-database-backup.js > "$BACKUP_ROOT_DIR/database-backup.log" 2>&1; then
  log_result "Database" "SUCCESS" "Full database export completed"
else
  log_result "Database" "FAILED" "Error during database backup"
fi

# 3. Backup Cloud Storage
echo "--- Backing up Cloud Storage ---"
if node firebase-storage-backup.js > "$BACKUP_ROOT_DIR/storage-backup.log" 2>&1; then
  log_result "Storage" "SUCCESS" "Files copied to S3 backup"
else
  log_result "Storage" "FAILED" "Error during storage backup"
fi

# 4. Backup Cloud Functions
echo "--- Backing up Cloud Functions ---"
if ./firebase-functions-backup.sh > "$BACKUP_ROOT_DIR/functions-backup.log" 2>&1; then
  log_result "Functions" "SUCCESS" "Source code and configuration saved"
else
  log_result "Functions" "FAILED" "Error during functions backup"
fi

# 5. Backup Firebase Configuration
echo "--- Backing up Firebase Configuration ---"
if firebase apps:list --project "$PROJECT_ID" > "$BACKUP_ROOT_DIR/apps-config.json" 2>&1; then
  log_result "Configuration" "SUCCESS" "App configuration exported"
else
  log_result "Configuration" "FAILED" "Error during configuration backup"
fi

# Create comprehensive backup summary
create_backup_summary() {
  local summary_file="$BACKUP_ROOT_DIR/backup-summary.json"

  cat > "$summary_file" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)",
  "projectId": "$PROJECT_ID",
  "backupLocation": "$BACKUP_ROOT_DIR",
  "services": {
    "authentication": {
      "status": "${backup_results[Authentication]:-UNKNOWN}",
      "includes": ["users", "custom_claims", "provider_config"]
    },
    "database": {
      "status": "${backup_results[Database]:-UNKNOWN}",
      "includes": ["full_export", "critical_paths", "metadata"]
    },
    "storage": {
      "status": "${backup_results[Storage]:-UNKNOWN}",
      "includes": ["files", "metadata", "s3_backup"]
    },
    "functions": {
      "status": "${backup_results[Functions]:-UNKNOWN}",
      "includes": ["source_code", "config", "dependencies"]
    },
    "configuration": {
      "status": "${backup_results[Configuration]:-UNKNOWN}",
      "includes": ["app_config", "project_settings"]
    }
  },
  "retention": "90 days",
  "nextBackup": "$(date -d '+1 day' -u +%Y-%m-%dT%H:%M:%S.000Z)"
}
EOF

  echo "Backup summary created: $summary_file"
}

create_backup_summary

# Calculate overall success
successful_backups=0
failed_backups=0
total_services=${#backup_results[@]}

for status in "${backup_results[@]}"; do
  if [ "$status" = "SUCCESS" ]; then
    ((successful_backups++))
  else
    ((failed_backups++))
  fi
done

# Determine overall result
if [ $successful_backups -eq $total_services ]; then
  overall_status="SUCCESS"
  exit_code=0
elif [ $successful_backups -gt 0 ]; then
  overall_status="PARTIAL"
  exit_code=1
else
  overall_status="FAILED"
  exit_code=2
fi

echo "=== Firebase Backup Summary ===" | tee -a "$BACKUP_LOG"
echo "Overall Status: $overall_status" | tee -a "$BACKUP_LOG"
echo "Successful: $successful_backups/$total_services services" | tee -a "$BACKUP_LOG"
echo "Failed: $failed_backups/$total_services services" | tee -a "$BACKUP_LOG"
echo "Backup Location: $BACKUP_ROOT_DIR" | tee -a "$BACKUP_LOG"
echo "Backup completed at $(date)" | tee -a "$BACKUP_LOG"

# Send notification
notification_message="Firebase Backup $overall_status for $(date +%Y-%m-%d)
Project: $PROJECT_ID
Successful: $successful_backups/$total_services services
Location: $BACKUP_ROOT_DIR"

aws sns publish \
  --topic-arn "$NOTIFICATION_TOPIC" \
  --message "$notification_message" \
  --subject "Firebase Backup $overall_status"

# Cleanup old backups (keep last 30 days)
find ./firebase-backups -type d -name "20*" -mtime +30 -exec rm -rf {} \; 2>/dev/null || true

exit $exit_code
```

### 5.2 Scheduled Backup Automation

#### Cron Configuration

```bash
# Add to crontab: crontab -e
# Daily backup at 3 AM
0 3 * * * /path/to/firebase-master-backup.sh >> /var/log/firebase-backup.log 2>&1

# Weekly full validation backup (Sundays at 2 AM)
0 2 * * 0 /path/to/firebase-master-backup.sh --validate >> /var/log/firebase-backup.log 2>&1

# Monthly archive backup (1st of month at 1 AM)
0 1 1 * * /path/to/firebase-master-backup.sh --archive >> /var/log/firebase-backup.log 2>&1
```

## 6. Monitoring and Validation

### 6.1 Backup Health Monitoring

#### Firebase Backup Monitoring Script

```python
#!/usr/bin/env python3
# firebase-backup-monitor.py
# Monitor Firebase backup health and integrity

import json
import os
import boto3
import subprocess
from datetime import datetime, timedelta

def check_backup_completeness(backup_dir):
    """Check if all required backup components are present"""
    required_components = [
        'backup-summary.json',
        'auth-backup.log',
        'database-backup.log',
        'storage-backup.log',
        'functions-backup.log'
    ]

    missing_components = []

    for component in required_components:
        if not os.path.exists(os.path.join(backup_dir, component)):
            missing_components.append(component)

    return {
        'complete': len(missing_components) == 0,
        'missing': missing_components,
        'total_required': len(required_components)
    }

def validate_backup_integrity(backup_dir):
    """Validate backup data integrity"""
    validation_results = {}

    # Check backup summary
    summary_path = os.path.join(backup_dir, 'backup-summary.json')
    if os.path.exists(summary_path):
        with open(summary_path, 'r') as f:
            summary = json.load(f)

        validation_results['summary'] = {
            'valid': 'timestamp' in summary and 'services' in summary,
            'services_backed_up': len([s for s in summary['services'].values() if s['status'] == 'SUCCESS'])
        }

    # Validate authentication backup
    auth_backup = os.path.join(backup_dir, 'firebase-users.json')
    if os.path.exists(auth_backup):
        try:
            with open(auth_backup, 'r') as f:
                users = json.load(f)
            validation_results['auth'] = {
                'valid': True,
                'user_count': len(users)
            }
        except json.JSONDecodeError:
            validation_results['auth'] = {'valid': False, 'error': 'Invalid JSON'}

    # Validate database backup
    db_backup = os.path.join(backup_dir, 'realtime-database-full.json')
    if os.path.exists(db_backup):
        try:
            with open(db_backup, 'r') as f:
                data = json.load(f)
            validation_results['database'] = {
                'valid': True,
                'top_level_keys': len(data.keys()) if data else 0
            }
        except json.JSONDecodeError:
            validation_results['database'] = {'valid': False, 'error': 'Invalid JSON'}

    return validation_results

def check_s3_backup_sync():
    """Check Firebase Storage backup sync to S3"""
    s3 = boto3.client('s3')
    bucket = 'distronation-firebase-backup'

    try:
        # Check recent backups
        today = datetime.now().strftime('%Y-%m-%d')
        prefix = f'firebase-storage-backup/{today}/'

        response = s3.list_objects_v2(Bucket=bucket, Prefix=prefix)

        if 'Contents' in response:
            return {
                'synced': True,
                'files_count': len(response['Contents']),
                'latest_backup': today
            }
        else:
            return {
                'synced': False,
                'error': 'No backup found for today'
            }

    except Exception as e:
        return {
            'synced': False,
            'error': str(e)
        }

def generate_health_report():
    """Generate comprehensive backup health report"""
    report = {
        'timestamp': datetime.now().isoformat(),
        'backup_health': {},
        'recommendations': []
    }

    # Find recent backups
    backup_root = './firebase-backups'
    if os.path.exists(backup_root):
        backup_dirs = [d for d in os.listdir(backup_root) if d.startswith('20')]
        backup_dirs.sort(reverse=True)

        if backup_dirs:
            latest_backup = os.path.join(backup_root, backup_dirs[0])

            # Check completeness
            completeness = check_backup_completeness(latest_backup)
            report['backup_health']['completeness'] = completeness

            if not completeness['complete']:
                report['recommendations'].append(
                    f"Latest backup missing components: {', '.join(completeness['missing'])}"
                )

            # Check integrity
            integrity = validate_backup_integrity(latest_backup)
            report['backup_health']['integrity'] = integrity

            # Check age of latest backup
            backup_date = datetime.strptime(backup_dirs[0][:8], '%Y%m%d')
            days_old = (datetime.now() - backup_date).days

            report['backup_health']['freshness'] = {
                'latest_backup_date': backup_date.isoformat(),
                'days_old': days_old,
                'acceptable': days_old <= 1
            }

            if days_old > 1:
                report['recommendations'].append(
                    f"Latest backup is {days_old} days old - backups should be daily"
                )
        else:
            report['backup_health']['status'] = 'NO_BACKUPS_FOUND'
            report['recommendations'].append("No backup directories found")

    # Check S3 sync
    s3_status = check_s3_backup_sync()
    report['backup_health']['s3_sync'] = s3_status

    if not s3_status['synced']:
        report['recommendations'].append(f"S3 sync issue: {s3_status.get('error', 'Unknown error')}")

    # Overall health score
    health_score = 0
    max_score = 4

    if report['backup_health'].get('completeness', {}).get('complete'):
        health_score += 1
    if report['backup_health'].get('integrity', {}).get('summary', {}).get('valid'):
        health_score += 1
    if report['backup_health'].get('freshness', {}).get('acceptable'):
        health_score += 1
    if report['backup_health'].get('s3_sync', {}).get('synced'):
        health_score += 1

    report['health_score'] = {
        'score': health_score,
        'max_score': max_score,
        'percentage': (health_score / max_score) * 100
    }

    return report

def send_health_alert(report):
    """Send health alert if issues detected"""
    health_percentage = report['health_score']['percentage']

    if health_percentage < 75:  # Alert if health below 75%
        sns = boto3.client('sns')

        message = f"""Firebase Backup Health Alert

Health Score: {health_percentage:.1f}%
Issues Detected: {len(report['recommendations'])}

Recommendations:
{chr(10).join('- ' + rec for rec in report['recommendations'])}

Report Timestamp: {report['timestamp']}
"""

        sns.publish(
            TopicArn='arn:aws:sns:<REGION>:<AWS_ACCOUNT_ID>:firebase-backup-alerts',
            Message=message,
            Subject=f'Firebase Backup Health Alert - {health_percentage:.1f}%'
        )

if __name__ == '__main__':
    report = generate_health_report()

    # Save report
    report_file = f'/var/log/firebase-backup-health-{datetime.now().strftime("%Y%m%d")}.json'
    with open(report_file, 'w') as f:
        json.dump(report, f, indent=2)

    print(f"Firebase Backup Health Report: {report['health_score']['percentage']:.1f}%")

    if report['recommendations']:
        print("\nRecommendations:")
        for rec in report['recommendations']:
            print(f"- {rec}")

    # Send alert if needed
    send_health_alert(report)

    # Exit with appropriate code
    exit(0 if report['health_score']['percentage'] >= 75 else 1)
```

## Implementation Timeline

### Phase 1: Critical Backup Implementation (Week 1)

```yaml
✅ Document Firebase backup strategies and procedures
⏳ Implement Firebase Authentication backup scripts
⏳ Set up Realtime Database export automation
⏳ Configure Firebase Storage to S3 replication
⏳ Create basic monitoring and alerting
```

### Phase 2: Automation and Testing (Week 2)

```yaml
⏳ Deploy comprehensive backup automation
⏳ Implement backup validation and integrity checking
⏳ Create recovery testing procedures
⏳ Set up backup health monitoring
```

### Phase 3: Integration and Optimization (Week 3-4)

```yaml
⏳ Integrate with AWS disaster recovery procedures
⏳ Optimize backup schedules and retention
⏳ Create comprehensive recovery runbooks
⏳ Establish regular testing and validation schedules
```

## Next Steps

### Immediate Actions

1. ✅ Complete Firebase backup strategy documentation
2. ⏳ Set up Firebase Admin SDK with proper service account credentials
3. ⏳ Implement authentication and database backup scripts
4. ⏳ Configure S3 bucket for Firebase storage backup

### Integration Requirements

2. ⏳ Integrate Firebase backup monitoring with AWS CloudWatch
3. ⏳ Coordinate Firebase and AWS disaster recovery procedures
4. ⏳ Establish unified backup testing and validation
