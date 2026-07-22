const test = require("node:test");
const assert = require("node:assert/strict");
const {isLifetimePremiumAccount} = require("../entitlements");

test("grants lifetime premium only to the verified configured email", () => {
  assert.equal(isLifetimePremiumAccount({
    token: {email: "megnifylabs@gmail.com", email_verified: true},
  }), true);
  assert.equal(isLifetimePremiumAccount({
    token: {email: " MEGNIFYLABS@GMAIL.COM ", email_verified: true},
  }), true);
  assert.equal(isLifetimePremiumAccount({
    token: {email: "megnifylabs@gmail.com", email_verified: false},
  }), false);
  assert.equal(isLifetimePremiumAccount({
    token: {email: "another@example.com", email_verified: true},
  }), false);
  assert.equal(isLifetimePremiumAccount({}), false);
});
