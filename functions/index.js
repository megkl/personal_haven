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

const aiApiKey = defineSecret("AI_API_KEY");
const aiModel = "gpt-4o-mini";
const aiEndpoint = "https://api.openai.com/v1/chat/completions";

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
