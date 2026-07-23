const {setGlobalOptions} = require("firebase-functions");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();
setGlobalOptions({maxInstances: 10});

const lifetimePremiumEmail = "megnifylabs@gmail.com";

function isLifetimePremiumAccount(auth) {
  const token = auth && auth.token ? auth.token : {};
  const email = typeof token.email === "string" ?
    token.email.trim().toLowerCase() : "";
  return token.email_verified === true && email === lifetimePremiumEmail;
}

function addDays(date, days) {
  return new Date(date.getTime() + days * 24 * 60 * 60 * 1000);
}

exports.syncPremiumEntitlement = onCall(
    {region: "us-central1", enforceAppCheck: true},
    async (request) => {
      if (!request.auth) {
        throw new HttpsError("unauthenticated", "Sign in required.");
      }

      const isLifetimePremium = isLifetimePremiumAccount(request.auth);
      await admin.firestore()
          .collection("users")
          .doc(request.auth.uid)
          .set({isPremium: isLifetimePremium}, {merge: true});

      return {isLifetimePremium};
    },
);

exports.startTrial = onCall(
    {region: "us-central1", enforceAppCheck: true},
    async (request) => {
      if (!request.auth) {
        throw new HttpsError("unauthenticated", "Sign in required.");
      }

      const db = admin.firestore();
      const uid = request.auth.uid;
      const userRef = db.collection("users").doc(uid);
      const subscriptionsRef = userRef.collection("subscriptions");
      const trialRef = subscriptionsRef.doc("free_trial");
      const previousTrials = subscriptionsRef
          .where("isTrialUsed", "==", true)
          .limit(1);

      return db.runTransaction(async (transaction) => {
        const userSnap = await transaction.get(userRef);
        const previousTrialSnap = await transaction.get(previousTrials);
        if ((userSnap.exists && userSnap.data().trialUsed === true) ||
            !previousTrialSnap.empty) {
          throw new HttpsError(
              "already-exists",
              "The free trial has already been used.",
          );
        }

        const now = new Date();
        if (!userSnap.exists) {
          const token = request.auth.token || {};
          const displayName = typeof token.name === "string" ?
            token.name.trim() : "";
          const nameParts = displayName ? displayName.split(/\s+/) : [];
          transaction.set(userRef, {
            user_id: uid,
            email: typeof token.email === "string" ? token.email : "",
            username: null,
            firstName: nameParts.length ? nameParts[0] : null,
            lastName: nameParts.length > 1 ? nameParts.slice(1).join(" ") : null,
            avatarUrl: typeof token.picture === "string" ? token.picture : null,
            bio: null,
            createdAt: now.toISOString(),
            lastLoginAt: now.toISOString(),
            isPremium: false,
            preferences: null,
          });
        }

        const subscription = {
          id: trialRef.id,
          userId: uid,
          plan: "free",
          status: "active",
          startDate: now.toISOString(),
          expiryDate: addDays(now, 7).toISOString(),
          paymentMethod: null,
          transactionRef: null,
          amountPaid: 0,
          currency: "KES",
          isTrialUsed: true,
          source: "server_trial",
          verifiedAt: now.toISOString(),
        };
        transaction.set(trialRef, subscription);
        transaction.set(userRef, {trialUsed: true}, {merge: true});
        return {subscription};
      });
    },
);

exports.deleteAccount = onCall(
    {region: "us-central1", enforceAppCheck: true},
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
