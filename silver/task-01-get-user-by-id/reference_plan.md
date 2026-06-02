# Root cause

`getUserById`, `updateUser`, and `deleteUser` all use `WHERE id = ?` in their SQLite queries, but the column in the `users` table is `user_id` (defined in `DatabaseHelper._createDB`).

SQLite silently returns zero rows for a WHERE clause on a non-existent column name, so the methods always return null/false without throwing.

# Fix sketch

Change the `where` clause in all three methods from `'id = ?'` to `'user_id = ?'`.

# Tests

- Create a user, then call `getUserById` with the returned ID — should return a non-null `User` with matching `id`.
- Call `updateUser` on an existing user and verify the returned bool is `true`.
- Call `deleteUser` on an existing user and verify subsequent `getUserById` returns `null`.
