const aiPlanLimits = Object.freeze({
  free: Object.freeze({requestLimit: 10, tokenLimit: 10000, window: "week"}),
  weekly: Object.freeze({
    requestLimit: 50,
    tokenLimit: 60000,
    window: "week",
  }),
  monthly: Object.freeze({
    requestLimit: 180,
    tokenLimit: 180000,
    window: "month",
  }),
  yearly: Object.freeze({
    requestLimit: 220,
    tokenLimit: 200000,
    window: "month",
  }),
  override: Object.freeze({
    requestLimit: 250,
    tokenLimit: 250000,
    window: "month",
  }),
});

// Each paid request reserves its bounded worst-case token allowance before it
// reaches OpenAI. This intentionally charges conservatively so concurrent
// requests cannot push an account beyond its plan budget.
const aiOperationTokenReservations = Object.freeze({
  parseAction: 1800,
  promptSuggestions: 1000,
  companionChat: 5500,
});

module.exports = {aiOperationTokenReservations, aiPlanLimits};
