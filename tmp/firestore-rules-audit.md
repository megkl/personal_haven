# Firestore Security Rules audit

## Result

The former recursive owner-write rule allowed any authenticated user to grant
themselves premium access and fabricate subscription history. The replacement
uses default-deny rules, explicit collection matches, owner isolation, strict
field allowlists, type/length/value bounds, immutable record identity, and
server-only writes for `isPremium`, `trialUsed`, subscriptions, AI usage, and
chat history.

The lifetime entitlement does not trust Firestore profile data. The callable
function compares the verified Firebase Auth token email with
`megnifylabs@gmail.com`. Trial creation is transactional and checks both the
server marker and historical trial records. Store subscriptions remain written
only after backend verification.

## Residual limitation

Firestore Rules cannot iterate arbitrary lists. Shopping items and journal tags
are size-bounded, while the Flutter models parse their nested values. Since all
such records are owner-private, malformed nested values cannot affect another
user or elevate access.

## Auditor assessment

```json
{
  "score": 4,
  "critical_issues": [],
  "warnings": [
    "Nested shopping item and journal tag element types cannot be exhaustively validated in Firestore Rules; list sizes are bounded."
  ],
  "strengths": [
    "Default deny and strict per-user path isolation",
    "Premium, trial, subscription, chat, and AI usage writes are server-only",
    "Create and update schemas reject unknown fields and oversized values",
    "Document IDs and user IDs are immutable and must match the path",
    "Account deletion remains restricted to the authenticated Admin callable"
  ]
}
```
