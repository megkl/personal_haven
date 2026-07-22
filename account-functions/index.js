const {setGlobalOptions} = require("firebase-functions");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();
setGlobalOptions({maxInstances: 10});

exports.deleteAccount = onCall(
    {region: "us-central1"},
    async (request) => {
      if (!request.auth) {
        throw new HttpsError("unauthenticated", "Sign in required.");
      }

      const uid = request.auth.uid;
      const db = admin.firestore();
      const userRef = db.collection("users").doc(uid);

      try {
        // User-owned app data is stored below users/{uid}. recursiveDelete
        // removes the profile plus every current and future subcollection.
        await db.recursiveDelete(userRef);
        await admin.auth().deleteUser(uid);
        console.info("User account deleted", {uid});
        return {ok: true};
      } catch (error) {
        console.error("User account deletion failed", {
          uid,
          message: error.message,
        });
        throw new HttpsError(
            "internal",
            "Your account could not be deleted. Please try again.",
        );
      }
    },
);
