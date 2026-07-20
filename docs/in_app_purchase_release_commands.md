# In-App Purchase Release Commands

Use this checklist after the app has been uploaded to App Store Connect or Google Play Console and the subscription products have been created.

## Product IDs

Create these exact subscription product IDs in both stores:

```text
personal_haven_weekly
personal_haven_monthly
personal_haven_yearly
```

The Android package name currently used by the app is:

```text
com.megnifylabs.personal_haven
```

## 1. Set Firebase Function Secrets

Run these from the project root:

```bash
npx -y firebase-tools@latest functions:secrets:set APPLE_SHARED_SECRET
npx -y firebase-tools@latest functions:secrets:set ANDROID_PACKAGE_NAME
npx -y firebase-tools@latest functions:secrets:set GOOGLE_PLAY_SERVICE_ACCOUNT_JSON
```

When prompted:

- `APPLE_SHARED_SECRET`: paste the app-specific shared secret from App Store Connect.
- `ANDROID_PACKAGE_NAME`: paste `com.megnifylabs.personal_haven`.
- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`: paste the full downloaded JSON key for the Google Play service account.

## 2. Deploy Backend Validation

Deploy the Cloud Functions after the secrets are set:

```bash
npx -y firebase-tools@latest deploy --only functions
```

Confirm these functions exist in Firebase Console:

```text
parseAssistantAction
verifyStorePurchase
```

## 3. Deploy Firestore Rules and Indexes

Run:

```bash
npx -y firebase-tools@latest deploy --only firestore
```

This deploys:

```text
firestore.rules
firestore.indexes.json
```

## 4. Android Test Flow

After uploading a signed Android build to an internal testing track:

```bash
flutter build apk --release
```

Then:

1. Upload the signed build to Google Play Console.
2. Add your Google account as a license tester.
3. Install the app from the internal testing link.
4. Open the subscription screen.
5. Buy a subscription using a Google test payment method.
6. Check Firestore:

```text
users/{uid}/subscriptions/{subscriptionId}
users/{uid}.isPremium
```

Expected result:

```text
status = active
paymentMethod = store
productId = personal_haven_monthly/weekly/yearly
isPremium = true
```

## 5. iOS Sandbox Test Flow

After creating the app and subscriptions in App Store Connect:

```bash
flutter build ios --release
```

Then:

1. Upload the iOS build with Xcode or Transporter.
2. Add a Sandbox Tester in App Store Connect.
3. Install the app with TestFlight or a local signed build.
4. Sign into the sandbox Apple account when prompted by the purchase sheet.
5. Buy a subscription.
6. Check Firestore:

```text
users/{uid}/subscriptions/{subscriptionId}
users/{uid}.isPremium
```

Expected result:

```text
status = active
paymentMethod = store
store = apple
isPremium = true
```

## 6. Restore Purchase Test

After one successful purchase:

1. Delete and reinstall the app.
2. Sign in with the same user.
3. Open the subscription screen.
4. Tap Restore purchases.
5. Check Firestore.

Expected result:

- Premium access is restored.
- The backend verifies the receipt/token again.
- Duplicate subscription records are not created for the same transaction.

## 7. Useful Debug Commands

View function logs:

```bash
npx -y firebase-tools@latest functions:log
```

Deploy only functions:

```bash
npx -y firebase-tools@latest deploy --only functions
```

Deploy only Firestore:

```bash
npx -y firebase-tools@latest deploy --only firestore
```

Run local lint before deploy:

```bash
npm --prefix functions run lint
```

Run Flutter analysis:

```bash
flutter analyze
```

## Notes

- Store purchases cannot be fully tested with fake product IDs.
- Google Play validation requires the app to be installed from a Play testing track.
- Apple validation requires App Store Connect products and a sandbox/TestFlight flow.
- Do not commit service account JSON files to the repository.
- Do not place store secrets in Flutter code.
