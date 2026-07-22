const lifetimePremiumEmail = "megnifylabs@gmail.com";

/**
 * Lifetime premium is tied to the verified Firebase Auth identity, never to
 * client-controlled profile data.
 * @param {object} auth Callable Firebase Auth context.
 * @return {boolean} Whether this is the single lifetime account.
 */
function isLifetimePremiumAccount(auth) {
  const token = auth && auth.token ? auth.token : {};
  const email = typeof token.email === "string" ?
    token.email.trim().toLowerCase() : "";
  return token.email_verified === true && email === lifetimePremiumEmail;
}

module.exports = {isLifetimePremiumAccount, lifetimePremiumEmail};
