/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const admin = require("firebase-admin");
const crypto = require("crypto");

admin.initializeApp();

const aiApiKey = defineSecret("AI_API_KEY");
const appleSharedSecret = defineSecret("APPLE_SHARED_SECRET");
const googlePlayServiceAccountJson = defineSecret(
    "GOOGLE_PLAY_SERVICE_ACCOUNT_JSON",
);
const androidPackageName = defineSecret("ANDROID_PACKAGE_NAME");
const aiModel = "gpt-4o-mini";
const aiEndpoint = "https://api.openai.com/v1/chat/completions";

const storeProducts = {
  personal_haven_weekly: {
    plan: "weekly",
    durationDays: 7,
    amountPaid: 30,
  },
  personal_haven_monthly: {
    plan: "monthly",
    durationDays: 30,
    amountPaid: 100,
  },
  personal_haven_yearly: {
    plan: "yearly",
    durationDays: 365,
    amountPaid: 800,
  },
};

const assistantSystemPrompt = [
  "You parse Personal Haven assistant messages into JSON only.",
  "Do not execute actions. Do not include markdown.",
  "Return one object with keys: intent, confidence, action, reply,",
  "fields, missingFields, suggestedPrompts.",
  "intent must be one of task, goal, event, mood, food, journal,",
  "transaction, summary, unknown.",
  "action must be create, update, answer, or unknown.",
  "fields is an object. Use null for missing values.",
  "missingFields is an array of required field names still needed.",
  "suggestedPrompts is an array of 2 to 4 short user reply chips.",
  "For task fields include title, priority, dueDateText, category.",
  "Task priority must be urgent, high, medium, or low.",
  "Map not urgent, not so urgent, no rush, can wait, whenever,",
  "or later to low priority.",
  "For goal fields include title, targetValue, unit, targetDateText.",
  "For event fields include title, dateText, timeText, location.",
  "For mood fields include label and notes.",
  "For food fields include foodName, mealType, calories, protein,",
  "carbs, fat.",
  "For journal fields include title, content, category.",
  "For transaction fields include type, amount, category, description.",
  "If key details are missing, reply with the next short question.",
  "If all fields are present, reply with a brief confirmation question.",
].join(" ");

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({maxInstances: 10});

exports.parseAssistantAction = onCall(
    {secrets: [aiApiKey], region: "us-central1"},
    async (request) => {
      if (!request.auth) {
        throw new HttpsError("unauthenticated", "Sign in required.");
      }

      const message = request.data && request.data.message;
      if (!message || typeof message !== "string") {
        throw new HttpsError("invalid-argument", "Message is required.");
      }

      const response = await fetch(aiEndpoint, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${aiApiKey.value()}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: aiModel,
          temperature: 0.1,
          response_format: {type: "json_object"},
          messages: [
            {role: "system", content: assistantSystemPrompt},
            {role: "user", content: message.slice(0, 1200)},
          ],
        }),
      });

      if (!response.ok) {
        throw new HttpsError("internal", "AI request failed.");
      }

      const payload = await response.json();
      const content = payload &&
          payload.choices &&
          payload.choices[0] &&
          payload.choices[0].message &&
          payload.choices[0].message.content;

      if (!content || typeof content !== "string") {
        throw new HttpsError("internal", "AI response was empty.");
      }

      try {
        return normalizeAssistantResult(JSON.parse(content));
      } catch (error) {
        throw new HttpsError("internal", "AI response was not valid JSON.");
      }
    },
);

exports.verifyStorePurchase = onCall(
    {
      secrets: [
        appleSharedSecret,
        googlePlayServiceAccountJson,
        androidPackageName,
      ],
      region: "us-central1",
    },
    async (request) => {
      if (!request.auth) {
        throw new HttpsError("unauthenticated", "Sign in required.");
      }

      const data = request.data || {};
      const uid = request.auth.uid;
      const productId = stringField(data.productId, "productId");
      const receipt = stringField(
          data.serverVerificationData,
          "serverVerificationData",
      );
      const requestedPlan = stringField(data.plan, "plan");
      const source = stringField(data.verificationSource, "verificationSource")
          .toLowerCase();
      const transactionId = typeof data.transactionId === "string" ?
        data.transactionId :
        null;
      const product = storeProducts[productId];

      if (!product) {
        throw new HttpsError("invalid-argument", "Unknown store product.");
      }
      if (requestedPlan !== product.plan) {
        throw new HttpsError("invalid-argument", "Plan does not match.");
      }

      const verification = await verifyByStore({
        source,
        productId,
        receipt,
        transactionId,
      });
      const now = new Date();
      const fallbackExpiry = addDays(now, product.durationDays);
      const expiryDate = verification.expiryDate || fallbackExpiry;

      if (expiryDate <= now) {
        throw new HttpsError("failed-precondition", "Purchase is expired.");
      }

      const subscription = await writeVerifiedSubscription({
        uid,
        product,
        productId,
        transactionRef: verification.transactionRef || transactionId,
        expiryDate,
        store: verification.store,
      });

      return {
        ok: true,
        subscription,
      };
    },
);

/**
 * @param {object} options Store verification inputs.
 * @return {Promise<object>} Normalized verification result.
 */
async function verifyByStore(options) {
  if (options.source.includes("app_store") ||
      options.source.includes("ios")) {
    return verifyAppleReceipt(options);
  }
  if (options.source.includes("google_play") ||
      options.source.includes("android")) {
    return verifyGooglePlayPurchase(options);
  }

  throw new HttpsError(
      "invalid-argument",
      "Unsupported store verification source.",
  );
}

/**
 * @param {object} options Apple receipt verification inputs.
 * @return {Promise<object>} Normalized verification result.
 */
async function verifyAppleReceipt(options) {
  const password = appleSharedSecret.value();
  if (!password) {
    throw new HttpsError(
        "failed-precondition",
        "APPLE_SHARED_SECRET is not configured.",
    );
  }

  let payload = await postAppleReceipt(
      "https://buy.itunes.apple.com/verifyReceipt",
      options.receipt,
      password,
  );
  if (payload.status === 21007) {
    payload = await postAppleReceipt(
        "https://sandbox.itunes.apple.com/verifyReceipt",
        options.receipt,
        password,
    );
  }
  if (payload.status !== 0) {
    throw new HttpsError("permission-denied", "Apple receipt is invalid.");
  }

  const purchases = []
      .concat(payload.latest_receipt_info || [])
      .concat((payload.receipt && payload.receipt.in_app) || []);
  const purchase = newestMatchingPurchase(purchases, options.productId);
  if (!purchase) {
    throw new HttpsError(
        "permission-denied",
        "Apple receipt does not include this product.",
    );
  }

  return {
    store: "apple",
    transactionRef: purchase.original_transaction_id ||
      purchase.transaction_id ||
      options.transactionId,
    expiryDate: millisToDate(purchase.expires_date_ms),
  };
}

/**
 * @param {string} url Apple verifyReceipt endpoint.
 * @param {string} receipt Base64 receipt data.
 * @param {string} password App-specific shared secret.
 * @return {Promise<object>} Parsed response payload.
 */
async function postAppleReceipt(url, receipt, password) {
  const response = await fetch(url, {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({
      "receipt-data": receipt,
      password,
      "exclude-old-transactions": true,
    }),
  });
  if (!response.ok) {
    throw new HttpsError("unavailable", "Apple receipt check failed.");
  }
  return response.json();
}

/**
 * @param {Array<object>} purchases Receipt line items.
 * @param {string} productId Store product id.
 * @return {?object} Newest matching purchase.
 */
function newestMatchingPurchase(purchases, productId) {
  return purchases
      .filter((item) => item.product_id === productId)
      .sort((a, b) => Number(b.expires_date_ms || 0) -
        Number(a.expires_date_ms || 0))[0] || null;
}

/**
 * @param {object} options Google Play verification inputs.
 * @return {Promise<object>} Normalized verification result.
 */
async function verifyGooglePlayPurchase(options) {
  const packageName = androidPackageName.value();
  if (!packageName) {
    throw new HttpsError(
        "failed-precondition",
        "ANDROID_PACKAGE_NAME is not configured.",
    );
  }
  const accessToken = await googleAccessToken();
  const encodedPackage = encodeURIComponent(packageName);
  const encodedProduct = encodeURIComponent(options.productId);
  const encodedToken = encodeURIComponent(options.receipt);
  const baseUrl = "https://androidpublisher.googleapis.com/androidpublisher";
  const url = `${baseUrl}/v3/applications/${encodedPackage}/purchases/` +
    `subscriptions/${encodedProduct}/tokens/${encodedToken}`;
  const response = await fetch(url, {
    headers: {Authorization: `Bearer ${accessToken}`},
  });
  if (!response.ok) {
    throw new HttpsError(
        "permission-denied",
        "Google Play purchase is invalid.",
    );
  }

  const payload = await response.json();
  const expiryDate = millisToDate(payload.expiryTimeMillis);
  if (!expiryDate || expiryDate <= new Date()) {
    throw new HttpsError("failed-precondition", "Google purchase expired.");
  }
  await acknowledgeGooglePurchase({
    accessToken,
    packageName: encodedPackage,
    productId: encodedProduct,
    token: encodedToken,
    acknowledgementState: payload.acknowledgementState,
  });

  return {
    store: "google",
    transactionRef: payload.orderId || options.transactionId,
    expiryDate,
  };
}

/**
 * @return {Promise<string>} OAuth access token for Android Publisher API.
 */
async function googleAccessToken() {
  const serviceAccountJson = googlePlayServiceAccountJson.value();
  if (!serviceAccountJson) {
    throw new HttpsError(
        "failed-precondition",
        "GOOGLE_PLAY_SERVICE_ACCOUNT_JSON is not configured.",
    );
  }
  let credentials;
  try {
    credentials = JSON.parse(serviceAccountJson);
  } catch (error) {
    throw new HttpsError(
        "failed-precondition",
        "Google service account JSON is invalid.",
    );
  }

  const now = Math.floor(Date.now() / 1000);
  const assertion = signJwt({
    iss: credentials.client_email,
    scope: "https://www.googleapis.com/auth/androidpublisher",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }, credentials.private_key);

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {"Content-Type": "application/x-www-form-urlencoded"},
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }).toString(),
  });
  if (!response.ok) {
    throw new HttpsError(
        "unavailable",
        "Could not authorize Google Play validation.",
    );
  }
  const payload = await response.json();
  return payload.access_token;
}

/**
 * @param {object} claims JWT claims.
 * @param {string} privateKey PEM private key.
 * @return {string} Signed JWT.
 */
function signJwt(claims, privateKey) {
  const header = base64UrlJson({alg: "RS256", typ: "JWT"});
  const body = base64UrlJson(claims);
  const input = `${header}.${body}`;
  const signature = crypto
      .createSign("RSA-SHA256")
      .update(input)
      .sign(privateKey, "base64url");
  return `${input}.${signature}`;
}

/**
 * @param {object} value JSON object.
 * @return {string} Base64url encoded JSON.
 */
function base64UrlJson(value) {
  return Buffer.from(JSON.stringify(value)).toString("base64url");
}

/**
 * @param {object} options Google acknowledge inputs.
 * @return {Promise<void>}
 */
async function acknowledgeGooglePurchase(options) {
  if (options.acknowledgementState !== 0) return;

  const baseUrl = "https://androidpublisher.googleapis.com/androidpublisher";
  const url = `${baseUrl}/v3/applications/${options.packageName}/purchases/` +
    `subscriptions/${options.productId}/tokens/${options.token}:acknowledge`;
  await fetch(url, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${options.accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({}),
  });
}

/**
 * @param {object} options Subscription write inputs.
 * @return {Promise<object>} Subscription payload.
 */
async function writeVerifiedSubscription(options) {
  const db = admin.firestore();
  const userRef = db.collection("users").doc(options.uid);
  const subscriptionsRef = userRef.collection("subscriptions");
  const transactionRef = options.transactionRef ||
    `${options.store}:${options.productId}`;
  const duplicate = await subscriptionsRef
      .where("transactionRef", "==", transactionRef)
      .limit(1)
      .get();

  if (!duplicate.empty) {
    const doc = duplicate.docs[0];
    const data = doc.data();
    await userRef.set({isPremium: true}, {merge: true});
    return {...data, id: doc.id};
  }

  const now = new Date();
  const subRef = subscriptionsRef.doc();
  const active = await subscriptionsRef
      .where("status", "==", "active")
      .get();
  const batch = db.batch();
  active.docs.forEach((doc) => {
    batch.update(doc.ref, {status: "expired"});
  });

  const subscription = {
    id: subRef.id,
    userId: options.uid,
    plan: options.product.plan,
    status: "active",
    startDate: now.toISOString(),
    expiryDate: options.expiryDate.toISOString(),
    paymentMethod: "store",
    transactionRef,
    amountPaid: options.product.amountPaid,
    currency: "KES",
    isTrialUsed: true,
    store: options.store,
    productId: options.productId,
    verifiedAt: now.toISOString(),
  };
  batch.set(subRef, subscription);
  batch.set(userRef, {isPremium: true}, {merge: true});
  await batch.commit();
  return subscription;
}

/**
 * @param {object} source Source object.
 * @param {string} name Field name.
 * @return {string} Required string value.
 */
function stringField(source, name) {
  const value = source[name];
  if (typeof value !== "string" || value.trim() === "") {
    throw new HttpsError("invalid-argument", `${name} is required.`);
  }
  return value.trim();
}

/**
 * @param {Date} date Starting date.
 * @param {number} days Days to add.
 * @return {Date} Result date.
 */
function addDays(date, days) {
  return new Date(date.getTime() + days * 24 * 60 * 60 * 1000);
}

/**
 * @param {string|number|undefined} value Milliseconds since epoch.
 * @return {?Date} Date if valid.
 */
function millisToDate(value) {
  if (value === undefined || value === null || value === "") return null;
  const millis = Number(value);
  if (!Number.isFinite(millis)) return null;
  return new Date(millis);
}

/**
 * Keeps the callable response predictable for Flutter.
 * @param {object} result Parsed model output.
 * @return {object} Normalized assistant result.
 */
function normalizeAssistantResult(result) {
  const allowedIntents = [
    "task",
    "goal",
    "event",
    "mood",
    "food",
    "journal",
    "transaction",
    "summary",
    "unknown",
  ];
  const intent = allowedIntents.includes(result.intent) ?
    result.intent :
    "unknown";

  return {
    intent,
    confidence: Number(result.confidence || 0),
    action: typeof result.action === "string" ? result.action : "unknown",
    reply: typeof result.reply === "string" ? result.reply : null,
    fields: result.fields && typeof result.fields === "object" ?
      result.fields :
      {},
    missingFields: Array.isArray(result.missingFields) ?
      result.missingFields.filter((field) => typeof field === "string") :
      [],
    suggestedPrompts: Array.isArray(result.suggestedPrompts) ?
      result.suggestedPrompts.filter((prompt) => typeof prompt === "string") :
      [],
  };
}

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
