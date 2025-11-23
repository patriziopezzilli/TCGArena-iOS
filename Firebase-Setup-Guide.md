# Firebase Configuration Guide for TCG Arena

## Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: "TCG Arena"
4. Enable Google Analytics (recommended)
5. Choose or create a Google Analytics account

## Step 2: Add iOS App to Firebase Project
1. In Firebase Console, click "Add app" and select iOS
2. Enter iOS bundle ID: `com.tcgarena.ios`
3. Enter app nickname: "TCG Arena iOS"
4. Download the `GoogleService-Info.plist` file
5. Add this file to your Xcode project (drag into TCG Arena folder)

## Step 3: Firebase SDK Installation
The project uses Swift Package Manager for Firebase SDK integration.

### Required Firebase Services:
- Firebase Auth (Authentication)
- Firebase Firestore (Database)
- Firebase Storage (File storage)
- Firebase Analytics (Analytics)

### Installation Steps:
1. Open Xcode project
2. Go to File > Add Package Dependencies
3. Enter URL: `https://github.com/firebase/firebase-ios-sdk`
4. Select "Up to Next Major Version" and click Add Package
5. Select the following products:
   - FirebaseAuth
   - FirebaseFirestore
   - FirebaseStorage
   - FirebaseAnalytics

## Step 4: Enable Firebase Services
In Firebase Console, enable:
1. **Authentication** > Sign-in method > Email/Password
2. **Firestore Database** > Create database (Start in test mode)
3. **Storage** > Get started (Start in test mode)

## Step 5: Security Rules
Update Firestore and Storage security rules as needed for production.

## Note
After downloading GoogleService-Info.plist, place it in the TCG Arena folder and add it to the Xcode project target.