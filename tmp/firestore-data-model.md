# Firestore access model

All user data is private and lives below `users/{uid}`. A signed-in user may
read their profile and their own subcollections. The client may create, update,
and delete only validated task, journal, goal, event, transaction, mood, food,
and shopping-list documents whose `userId` and document `id` match the path.

The `isPremium` and `trialUsed` profile fields are server-owned. Subscription,
AI-usage, and chat documents are server-written and client-readable. Cloud
Functions use the Admin SDK for those writes. Unknown collections and all
cross-user access are denied.

Queries in the current repositories are scoped directly to
`users/{currentUid}/{collection}`. No collection-group or public query is used.

Shopping list items and journal tags are bounded lists. Firestore Rules cannot
iterate an arbitrary list to validate every nested element, so the rules cap
their sizes; the Dart model performs the element-level parsing.
