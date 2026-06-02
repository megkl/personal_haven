#!/bin/bash
# Patches Firebase pods to compile on Xcode 15.2 / Swift 5.9
# Removes Swift 5.10-only syntax: nonisolated(unsafe), sending, internal/package import

PODS_DIR="$(dirname "$0")/Pods"

patch_file() {
  local f="$1"
  sed -i '' \
    -e 's/nonisolated(unsafe) //g' \
    -e 's/throws -> sending Any/throws -> Any/g' \
    -e 's/initialState: sending /initialState: /g' \
    -e 's/internal import /import /g' \
    -e 's/package import /import /g' \
    "$f"
}

FILES=(
  "$PODS_DIR/FirebaseSharedSwift/FirebaseSharedSwift/Sources/third_party/FirebaseDataEncoder/FirebaseDataEncoder.swift"
  "$PODS_DIR/FirebaseCoreInternal/FirebaseCore/Internal/Sources/Utilities/FIRAllocatedUnfairLock.swift"
  "$PODS_DIR/FirebaseCoreInternal/FirebaseCore/Internal/Sources/HeartbeatLogging/HeartbeatsPayload.swift"
  "$PODS_DIR/FirebaseAuth/FirebaseAuth/Sources/Swift/Auth/Auth.swift"
  "$PODS_DIR/FirebaseAuth/FirebaseAuth/Sources/Swift/SystemService/AuthAPNSTokenManager.swift"
  "$PODS_DIR/FirebaseAuth/FirebaseAuth/Sources/Swift/MultiFactor/TOTP/TOTPSecret.swift"
  "$PODS_DIR/FirebaseAuth/FirebaseAuth/Sources/Swift/Backend/IdentityToolkitRequest.swift"
  "$PODS_DIR/FirebaseAuth/FirebaseAuth/Sources/Swift/Backend/RPC/SecureTokenRequest.swift"
  "$PODS_DIR/FirebaseAuth/FirebaseAuth/Sources/Swift/Utilities/AuthDefaultUIDelegate.swift"
  "$PODS_DIR/FirebaseFirestore/Firestore/Swift/Source/Codable/DocumentID.swift"
  "$PODS_DIR/FirebaseStorage/FirebaseStorage/Sources/Storage.swift"
  "$PODS_DIR/FirebaseStorage/FirebaseStorage/Sources/Internal/StorageTokenAuthorizer.swift"
  "$PODS_DIR/FirebaseStorage/FirebaseStorage/Sources/StorageUploadTask.swift"
)

for f in "${FILES[@]}"; do
  if [ -f "$f" ]; then
    patch_file "$f"
    echo "Patched: $f"
  fi
done

echo "All patches applied."
