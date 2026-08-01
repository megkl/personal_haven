const test = require("node:test");
const assert = require("node:assert/strict");
const {
  aiOperationTokenReservations,
  aiPlanLimits,
} = require("../ai-usage-config");

test("every AI operation reserves a positive bounded token allowance", () => {
  assert.deepEqual(Object.keys(aiOperationTokenReservations).sort(), [
    "companionChat",
    "parseAction",
    "promptSuggestions",
  ]);
  for (const reservation of Object.values(aiOperationTokenReservations)) {
    assert.equal(Number.isInteger(reservation), true);
    assert.equal(reservation > 0, true);
    assert.equal(reservation <= 10000, true);
  }
});

test("paid plans receive larger AI budgets than the free plan", () => {
  for (const plan of ["weekly", "monthly", "yearly", "override"]) {
    assert.equal(
        aiPlanLimits[plan].tokenLimit > aiPlanLimits.free.tokenLimit,
        true,
    );
    assert.equal(
        aiPlanLimits[plan].requestLimit > aiPlanLimits.free.requestLimit,
        true,
    );
  }
});

test("all plans enforce both request and token limits", () => {
  for (const limit of Object.values(aiPlanLimits)) {
    assert.equal(Number.isInteger(limit.requestLimit), true);
    assert.equal(Number.isInteger(limit.tokenLimit), true);
    assert.equal(["week", "month"].includes(limit.window), true);
  }
});
