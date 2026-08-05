const entitledStates = new Set([
  "SUBSCRIPTION_STATE_ACTIVE",
  "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
  "SUBSCRIPTION_STATE_CANCELED",
]);

/**
 * Parses and validates a Google Play RTDN payload.
 * @param {object} payload Decoded Pub/Sub message payload.
 * @param {string} expectedPackageName Android application ID.
 * @return {object} Validated RTDN details.
 */
function parsePlayRtdnPayload(payload, expectedPackageName) {
  if (!payload || typeof payload !== "object") {
    throw new Error("Google Play RTDN payload is missing.");
  }
  if (payload.packageName !== expectedPackageName) {
    throw new Error("Google Play RTDN package does not match this app.");
  }
  if (payload.testNotification) {
    return {kind: "test", packageName: payload.packageName};
  }

  const voided = payload.voidedPurchaseNotification;
  if (voided &&
      Number(voided.productType) === 1 &&
      typeof voided.purchaseToken === "string" &&
      voided.purchaseToken.trim() !== "") {
    return {
      kind: "subscription",
      packageName: payload.packageName,
      purchaseToken: voided.purchaseToken,
      productId: null,
      notificationType: 0,
    };
  }
  if (voided || payload.oneTimeProductNotification ||
      payload.pendingRefundReviewNotification) {
    return {kind: "ignored", packageName: payload.packageName};
  }

  const notification = payload.subscriptionNotification;
  if (!notification ||
      typeof notification.purchaseToken !== "string" ||
      notification.purchaseToken.trim() === "") {
    throw new Error("Google Play subscription notification is invalid.");
  }

  return {
    kind: "subscription",
    packageName: payload.packageName,
    purchaseToken: notification.purchaseToken,
    productId: typeof notification.subscriptionId === "string" ?
      notification.subscriptionId : null,
    notificationType: Number(notification.notificationType || 0),
  };
}

/**
 * Whether Google Play currently grants access for this subscription.
 * A canceled subscription remains entitled until its paid-through expiry.
 * @param {string} state Google Play subscription state.
 * @param {?Date} expiryDate Current line-item expiry.
 * @param {Date} now Comparison time.
 * @return {boolean} Whether premium access should remain active.
 */
function isEntitledPlaySubscription(state, expiryDate, now = new Date()) {
  return entitledStates.has(state) &&
    expiryDate instanceof Date &&
    !Number.isNaN(expiryDate.getTime()) &&
    expiryDate > now;
}

/**
 * Maps an inactive Google Play state to the app's subscription status.
 * @param {string} state Google Play subscription state.
 * @return {string} Firestore subscription status.
 */
function appStatusForPlayState(state) {
  if (state === "SUBSCRIPTION_STATE_CANCELED") return "cancelled";
  if (state === "SUBSCRIPTION_STATE_EXPIRED" ||
      state === "SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED") {
    return "expired";
  }
  return "pending";
}

module.exports = {
  appStatusForPlayState,
  isEntitledPlaySubscription,
  parsePlayRtdnPayload,
};
