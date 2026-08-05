const test = require("node:test");
const assert = require("node:assert/strict");
const {
  appStatusForPlayState,
  isEntitledPlaySubscription,
  parsePlayRtdnPayload,
} = require("../play-rtdn");

const packageName = "com.megnifylabs.personal_haven";

test("parses a subscription notification", () => {
  const result = parsePlayRtdnPayload({
    packageName,
    subscriptionNotification: {
      notificationType: 2,
      purchaseToken: "purchase-token",
      subscriptionId: "personal_haven_weekly",
    },
  }, packageName);

  assert.deepEqual(result, {
    kind: "subscription",
    packageName,
    purchaseToken: "purchase-token",
    productId: "personal_haven_weekly",
    notificationType: 2,
  });
});

test("accepts the Play Console test notification", () => {
  assert.deepEqual(parsePlayRtdnPayload({
    packageName,
    testNotification: {version: "1.0"},
  }, packageName), {kind: "test", packageName});
});

test("parses a voided subscription notification", () => {
  assert.deepEqual(parsePlayRtdnPayload({
    packageName,
    voidedPurchaseNotification: {
      purchaseToken: "voided-token",
      productType: 1,
      refundType: 1,
    },
  }, packageName), {
    kind: "subscription",
    packageName,
    purchaseToken: "voided-token",
    productId: null,
    notificationType: 0,
  });
});

test("ignores voided one-time products", () => {
  assert.deepEqual(parsePlayRtdnPayload({
    packageName,
    voidedPurchaseNotification: {
      purchaseToken: "one-time-token",
      productType: 2,
    },
  }, packageName), {kind: "ignored", packageName});
});

test("rejects notifications for a different package", () => {
  assert.throws(
      () => parsePlayRtdnPayload({
        packageName: "com.example.other",
        testNotification: {version: "1.0"},
      }, packageName),
      /package does not match/,
  );
});

test("keeps active, grace, and paid-through canceled access", () => {
  const now = new Date("2026-08-05T00:00:00Z");
  const future = new Date("2026-08-12T00:00:00Z");
  for (const state of [
    "SUBSCRIPTION_STATE_ACTIVE",
    "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
    "SUBSCRIPTION_STATE_CANCELED",
  ]) {
    assert.equal(isEntitledPlaySubscription(state, future, now), true);
  }
  assert.equal(isEntitledPlaySubscription(
      "SUBSCRIPTION_STATE_EXPIRED", future, now), false);
  assert.equal(isEntitledPlaySubscription(
      "SUBSCRIPTION_STATE_ACTIVE", now, now), false);
});

test("maps inactive Play states to app statuses", () => {
  assert.equal(appStatusForPlayState(
      "SUBSCRIPTION_STATE_CANCELED"), "cancelled");
  assert.equal(appStatusForPlayState(
      "SUBSCRIPTION_STATE_EXPIRED"), "expired");
  assert.equal(appStatusForPlayState(
      "SUBSCRIPTION_STATE_ON_HOLD"), "pending");
});
