const test = require("node:test");
const assert = require("node:assert/strict");
const {requiredString} = require("../request-fields");

test("reads store purchase fields from the callable request payload", () => {
  const data = {
    productId: " personal_haven_monthly ",
    serverVerificationData: "purchase-token",
    plan: "monthly",
    verificationSource: "google_play",
  };

  assert.equal(requiredString(data, "productId"), "personal_haven_monthly");
  assert.equal(
      requiredString(data, "serverVerificationData"),
      "purchase-token",
  );
  assert.equal(requiredString(data, "plan"), "monthly");
  assert.equal(requiredString(data, "verificationSource"), "google_play");
});

test("rejects missing, empty, and non-string request fields", () => {
  assert.equal(requiredString({}, "productId"), null);
  assert.equal(requiredString({productId: "  "}, "productId"), null);
  assert.equal(requiredString({productId: 42}, "productId"), null);
  assert.equal(requiredString(null, "productId"), null);
});
