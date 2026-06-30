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
const OpenAI = require("openai");

admin.initializeApp();

const aiApiKey = defineSecret("AI_API_KEY");
const aiModel = "gpt-4o-mini";
const aiEndpoint = "https://api.openai.com/v1/chat/completions";

const aiPlanLimits = {
  free: {limit: 20, window: "week"},
  weekly: {limit: 30, window: "week"},
  monthly: {limit: 300, window: "month"},
  yearly: {limit: 400, window: "month"},
  override: {limit: 300, window: "month"},
};

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
  "transaction, shopping, summary, unknown.",
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
  "Respect labeled journal input such as title: X content: Y.",
  "Also handle labels without colons, e.g. title Testing content I am testing.",
  "If journal content is present but category is missing, infer a useful",
  "category such as Notes, Gratitude, Work, Ideas, Health, or Reflection.",
  "For transaction fields include type, amount, category, description.",
  "Infer transaction type from spent, paid, bought, salary, earned, received.",
  "For shopping fields include itemName, quantity, listTitle, category,",
  "and shoppingItems.",
  "shoppingItems is an array of objects with itemName and quantity.",
  "Use shoppingItems when the user gives multiple items in one message.",
  "Separate examples like eggs 5 of them, milk 1 litre, flour 2kg.",
  "For shopping, quantity is optional. Do not ask for quantity if item names",
  "are already clear.",
  "Use shopping for groceries, shopping lists, buy, pick up, or add to list.",
  "Examples:",
  "Input: title: Testing content: I am testing => intent journal, fields",
  "{title: Testing, content: I am testing, category: Notes}.",
  "Input: shopping list, eggs 5 of them, milk ltre, flour 2kg => intent",
  "shopping, shoppingItems [{itemName: eggs, quantity: 5},",
  "{itemName: milk, quantity: ltre}, {itemName: flour, quantity: 2kg}].",
  "Input: I spent KES 500 on groceries => intent transaction, type expense,",
  "amount 500, category Groceries.",
  "If key details are missing, reply with the next short question.",
  "If all fields are present, reply with a brief confirmation question.",
].join(" ");

const assistantPromptSuggestionSystemPrompt = [
  "You write smart Personal Haven reply chips.",
  "Return JSON only with one key: suggestedPrompts.",
  "suggestedPrompts must be an array of 2 to 4 short user reply chips.",
  "Each chip should be natural, specific, and useful for the current question.",
  "Use the user's known context to make chips fit the thing they are creating.",
  "Keep chips under 28 characters when possible.",
  "Do not include markdown, explanations, or duplicate chips.",
  "Use local, everyday examples. If money is involved, KES is acceptable.",
  "For confirmation questions, use Save, Change something, and Cancel.",
  "For optional fields, include a Skip option.",
].join(" ");

const havenAiSystemPrompt = [
  "You are Haven AI, a warm, supportive assistant inside Personal Haven.",
  "You help users reflect, plan, journal, manage wellness, and stay motivated.",
  "You are not a doctor, therapist, lawyer, or financial advisor.",
  "If the user appears to be in crisis, encourage them to contact trusted",
  "people or emergency support.",
  "Keep responses gentle, practical, and concise.",
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
      let usage;
      try {
        usage = await reserveAssistantUsage(request.auth.uid);
      } catch (error) {
        if (error instanceof HttpsError) throw error;
        console.error("AI usage reservation failed", {
          uid: request.auth.uid,
          message: error.message,
        });
        throw new HttpsError("internal", "AI usage check failed.");
      }

      try {
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
          await logAiResponseFailure("parseAssistantAction", response);
          return unknownAssistantResult(usage);
        }

        const payload = await response.json();
        const content = payload &&
            payload.choices &&
            payload.choices[0] &&
            payload.choices[0].message &&
            payload.choices[0].message.content;

        if (!content || typeof content !== "string") {
          console.error("AI response was empty", {
            functionName: "parseAssistantAction",
            payloadKeys: payload ? Object.keys(payload) : [],
          });
          return unknownAssistantResult(usage);
        }

        return {
          ...normalizeAssistantResult(JSON.parse(content)),
          usage,
        };
      } catch (error) {
        console.error("AI parse request failed", {
          functionName: "parseAssistantAction",
          message: error.message,
        });
        return unknownAssistantResult(usage);
      }
    },
);

exports.generateAssistantPrompts = onCall(
    {secrets: [aiApiKey], region: "us-central1"},
    async (request) => {
      if (!request.auth) {
        throw new HttpsError("unauthenticated", "Sign in required.");
      }

      const data = request.data || {};
      const intent = typeof data.intent === "string" ? data.intent : "unknown";
      const field = typeof data.field === "string" ? data.field : "";
      const question = typeof data.question === "string" ? data.question : "";
      const userInput = typeof data.userInput === "string" ?
        data.userInput :
        "";
      const fallbackPrompts = Array.isArray(data.fallbackPrompts) ?
        data.fallbackPrompts.filter((prompt) => typeof prompt === "string") :
        [];
      const fields = data.fields && typeof data.fields === "object" ?
        data.fields :
        {};

      if (!question || !field) {
        throw new HttpsError(
            "invalid-argument",
            "Question and field are required.",
        );
      }

      const promptContext = JSON.stringify({
        intent,
        field,
        question,
        userInput: userInput.slice(0, 300),
        fields,
        fallbackPrompts,
      });

      try {
        const response = await fetch(aiEndpoint, {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${aiApiKey.value()}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            model: aiModel,
            temperature: 0.4,
            response_format: {type: "json_object"},
            messages: [
              {role: "system", content: assistantPromptSuggestionSystemPrompt},
              {role: "user", content: promptContext.slice(0, 1600)},
            ],
          }),
        });

        if (!response.ok) {
          await logAiResponseFailure("generateAssistantPrompts", response);
          return {suggestedPrompts: fallbackPrompts.slice(0, 4)};
        }

        const payload = await response.json();
        const content = payload &&
            payload.choices &&
            payload.choices[0] &&
            payload.choices[0].message &&
            payload.choices[0].message.content;

        if (!content || typeof content !== "string") {
          console.error("AI prompt response was empty", {
            functionName: "generateAssistantPrompts",
            payloadKeys: payload ? Object.keys(payload) : [],
          });
          return {suggestedPrompts: fallbackPrompts.slice(0, 4)};
        }

        const parsed = JSON.parse(content);
        return normalizePromptSuggestionResult(parsed, fallbackPrompts);
      } catch (error) {
        console.error("AI prompt request failed", {
          functionName: "generateAssistantPrompts",
          message: error.message,
        });
        return {suggestedPrompts: fallbackPrompts.slice(0, 4)};
      }
    },
);

exports.chatWithHavenAI = onCall(
    {secrets: [aiApiKey], region: "us-central1"},
    async (request) => {
      if (!request.auth) {
        throw new HttpsError("unauthenticated", "Please sign in first.");
      }

      const userId = request.auth.uid;
      const message = request.data && request.data.message;

      if (!message || typeof message !== "string") {
        throw new HttpsError("invalid-argument", "Message is required.");
      }

      const trimmedMessage = message.trim().slice(0, 2000);
      const db = admin.firestore();
      const chatsRef = db
          .collection("users")
          .doc(userId)
          .collection("chats");

      await chatsRef.add({
        role: "user",
        content: trimmedMessage,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const historySnap = await chatsRef
          .orderBy("createdAt", "desc")
          .limit(12)
          .get();
      const history = historySnap.docs
          .map((doc) => doc.data())
          .reverse()
          .filter((entry) => {
            return (entry.role === "user" || entry.role === "assistant") &&
              typeof entry.content === "string" &&
              entry.content.trim() !== "";
          })
          .map((entry) => ({
            role: entry.role,
            content: entry.content.slice(0, 1200),
          }));

      try {
        const openai = new OpenAI({apiKey: aiApiKey.value()});
        const response = await openai.responses.create({
          model: "gpt-4.1-mini",
          input: [
            {role: "system", content: havenAiSystemPrompt},
            ...history,
          ],
        });

        const aiText = response.output_text ||
          "I am here with you. Tell me a little more, and we can take it " +
          "one step at a time.";

        await chatsRef.add({
          role: "assistant",
          content: aiText,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return {reply: aiText};
      } catch (error) {
        console.error("Haven AI chat request failed", {
          uid: userId,
          message: error.message,
        });
        throw new HttpsError(
            "internal",
            "Haven AI could not reply just now. Please try again.",
        );
      }
    },
);

exports.verifyStorePurchase = onCall(
    {
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
 * Reserves one AI assistant action before any paid model request is made.
 * @param {string} uid Firebase Auth uid.
 * @return {Promise<object>} Usage metadata for the client.
 */
async function reserveAssistantUsage(uid) {
  const db = admin.firestore();
  const plan = await activeSubscriptionPlan(uid);
  const limit = aiPlanLimits[plan] || aiPlanLimits.free;
  const period = usagePeriod(limit.window);
  const usageRef = db
      .collection("users")
      .doc(uid)
      .collection("ai_usage")
      .doc(`assistant_${limit.window}_${period.key}`);

  return db.runTransaction(async (transaction) => {
    const snap = await transaction.get(usageRef);
    const current = snap.exists ? Number(snap.data().count || 0) : 0;
    if (current >= limit.limit) {
      throw new HttpsError(
          "resource-exhausted",
          `AI action limit reached. Your ${limit.window}ly limit is ` +
            `${limit.limit}. It resets on ${period.resetAt}.`,
          {
            plan,
            limit: limit.limit,
            used: current,
            remaining: 0,
            window: limit.window,
            resetAt: period.resetAt,
          },
      );
    }

    const next = current + 1;
    transaction.set(
        usageRef,
        {
          plan,
          count: next,
          limit: limit.limit,
          window: limit.window,
          periodKey: period.key,
          resetAt: period.resetAt,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true},
    );

    return {
      plan,
      limit: limit.limit,
      used: next,
      remaining: Math.max(limit.limit - next, 0),
      window: limit.window,
      resetAt: period.resetAt,
    };
  });
}

/**
 * @param {string} uid Firebase Auth uid.
 * @return {Promise<string>} Active plan used for AI limits.
 */
async function activeSubscriptionPlan(uid) {
  const db = admin.firestore();
  const userRef = db.collection("users").doc(uid);
  const userSnap = await userRef.get();
  const premiumOverride = userSnap.exists && userSnap.data().isPremium === true;
  const now = new Date();
  const snap = await userRef
      .collection("subscriptions")
      .where("status", "==", "active")
      .get();
  const active = snap.docs
      .map((doc) => doc.data())
      .filter((sub) => {
        const expiryDate = parseDateValue(sub.expiryDate);
        return expiryDate && expiryDate > now;
      })
      .sort((a, b) => {
        return parseDateValue(b.expiryDate) - parseDateValue(a.expiryDate);
      })[0];

  if (active && aiPlanLimits[active.plan]) return active.plan;
  if (premiumOverride) return "override";
  return "free";
}

/**
 * @param {string} window Billing window: week or month.
 * @return {object} Period key and reset date.
 */
function usagePeriod(window) {
  const now = new Date();
  if (window === "week") {
    const start = startOfUtcWeek(now);
    const reset = addDays(start, 7);
    return {
      key: start.toISOString().slice(0, 10),
      resetAt: reset.toISOString(),
    };
  }
  const start = new Date(Date.UTC(
      now.getUTCFullYear(),
      now.getUTCMonth(),
      1,
  ));
  const reset = new Date(Date.UTC(
      now.getUTCFullYear(),
      now.getUTCMonth() + 1,
      1,
  ));
  const month = String(start.getUTCMonth() + 1).padStart(2, "0");
  return {
    key: `${start.getUTCFullYear()}-${month}`,
    resetAt: reset.toISOString(),
  };
}

/**
 * @param {Date} date Date in the target week.
 * @return {Date} Monday 00:00 UTC.
 */
function startOfUtcWeek(date) {
  const start = new Date(Date.UTC(
      date.getUTCFullYear(),
      date.getUTCMonth(),
      date.getUTCDate(),
  ));
  const day = start.getUTCDay() || 7;
  start.setUTCDate(start.getUTCDate() - day + 1);
  return start;
}

/**
 * @param {string|Date|undefined} value Date-like value.
 * @return {?Date} Parsed date.
 */
function parseDateValue(value) {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (typeof value.toDate === "function") return value.toDate();
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

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
  throw new HttpsError(
      "failed-precondition",
      "Apple purchases are not configured for this app.",
  );
}

/**
 * @param {object} options Google Play verification inputs.
 * @return {Promise<object>} Normalized verification result.
 */
async function verifyGooglePlayPurchase(options) {
  throw new HttpsError(
      "failed-precondition",
      "Google Play purchases are not configured for this app.",
  );
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
    "shopping",
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

/**
 * Builds a non-failing assistant result when upstream AI is unavailable.
 * @param {object} usage Current usage metadata.
 * @return {object} Unknown assistant result.
 */
function unknownAssistantResult(usage) {
  return {
    intent: "unknown",
    confidence: 0,
    action: "unknown",
    reply: null,
    fields: {},
    missingFields: [],
    suggestedPrompts: [],
    usage,
  };
}

/**
 * Logs a sanitized upstream AI error response.
 * @param {string} functionName Callable function name.
 * @param {Response} response Fetch response.
 * @return {Promise<void>}
 */
async function logAiResponseFailure(functionName, response) {
  let body = "";
  try {
    body = await response.text();
  } catch (error) {
    body = `Could not read response body: ${error.message}`;
  }
  console.error("AI upstream request failed", {
    functionName,
    status: response.status,
    statusText: response.statusText,
    body: body.slice(0, 500),
  });
}

/**
 * Sanitizes model-generated reply chips for the assistant UI.
 * @param {object} result AI JSON result.
 * @param {string[]} fallbackPrompts Local fallback prompts.
 * @return {{suggestedPrompts: string[]}} Clean prompt result.
 */
function normalizePromptSuggestionResult(result, fallbackPrompts) {
  const seen = new Set();
  const suggestedPrompts = Array.isArray(result.suggestedPrompts) ?
    result.suggestedPrompts :
    [];
  const cleanPrompts = suggestedPrompts
      .filter((prompt) => typeof prompt === "string")
      .map((prompt) => prompt.trim())
      .filter((prompt) => prompt.length > 0 && prompt.length <= 48)
      .filter((prompt) => {
        const key = prompt.toLowerCase();
        if (seen.has(key)) return false;
        seen.add(key);
        return true;
      })
      .slice(0, 4);

  return {
    suggestedPrompts: cleanPrompts.length >= 2 ?
      cleanPrompts :
      fallbackPrompts.slice(0, 4),
  };
}

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
