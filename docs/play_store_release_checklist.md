# Google Play first-release checklist

## App identity

- App name: `Personal Haven`
- Package name: `com.megnifylabs.personal_haven`
- Version name: `1.0.0`
- Version code: `1`
- Firebase project: `personal-haven-405b9`

The package name cannot be changed after the first Play release. Increase the
version code for every later upload.

## 1. Create and protect the upload key

Create a private upload keystore outside version control, then copy
`android/key.properties.example` to `android/key.properties` and replace its
placeholders. Back up the keystore and its passwords in a password manager.

Use Play App Signing when creating the first Play release. The local key is the
upload key; Google Play protects the app-signing key used for distribution.

After creating the upload key, add its SHA-1 and SHA-256 fingerprints to the
Firebase Android app. After Play App Signing is enabled, also add the Play app
signing certificate fingerprints shown under Play Console > App integrity.

## 2. Build and inspect the bundle

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

Upload `build/app/outputs/bundle/release/app-release.aab` to the internal testing
track first. Resolve all Play pre-launch report failures before production.

## 3. Store listing

Prepare the following assets and text in Play Console:

- App icon: 512 x 512 PNG
- Feature graphic: 1024 x 500 JPG or PNG
- At least two phone screenshots
- Short description: maximum 80 characters
- Full description: maximum 4,000 characters
- App category, support email, and website
- Privacy policy: `https://personalhaven.megnifylabs.com/privacy-policy/`

## 4. App content declarations

Complete every Play Console declaration before review:

- Data safety, including Firebase services and account data
- Ads declaration
- App access instructions and a reviewer account if sign-in gates features
- Target audience and content rating questionnaire
- Health apps declaration, if Play Console classifies wellbeing features as health
- Exact-alarm access and microphone use, matching actual reminder and voice-input behavior
- Account deletion URL and in-app deletion flow for accounts created in the app

## 5. Subscriptions

Create and activate these subscription product IDs:

- `personal_haven_weekly`
- `personal_haven_monthly`
- `personal_haven_yearly`

Complete the backend and license-testing steps in
`docs/in_app_purchase_release_commands.md`. Purchases must be tested from an
internal Play track; a locally installed APK is not sufficient.

## 6. Release sequence

1. Upload the signed AAB to internal testing.
2. Add license testers and test sign-in, account deletion, notifications,
   microphone permission, subscriptions, restore purchases, and offline/error states.
3. Review Android vitals and the automated pre-launch report.
4. Promote the tested artifact to closed testing if the account requires it.
5. Complete staged production rollout only after all declarations are approved.
