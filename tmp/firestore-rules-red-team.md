# Firestore rules red-team results

- Unauthenticated profile or nested-data reads: denied.
- Authenticated cross-user reads/writes: denied by UID path ownership.
- Client sets `isPremium` during profile creation: denied unless false.
- Client changes `isPremium` or `trialUsed` later: denied by affected-key allowlist.
- Client creates/updates/deletes subscriptions: denied; Cloud Functions only.
- Client fabricates AI usage or chat history: denied; Cloud Functions only.
- Client changes a nested record's `userId` or uses an ID that differs from the
  document path: denied by the common record validator.
- Client adds undeclared fields or oversized strings/lists: denied by schema
  allowlists and bounds.
- Unknown top-level or nested collections: denied by default.
- Profile deletion from the client: denied; account deletion uses the callable
  Admin function so recursive deletion remains available.
