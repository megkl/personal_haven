# Bug: getUserById never finds a user

`UserRepository.getUserById` always returns `null` even when the user exists in the database.

The users table has a primary key column named `user_id`. After creating a user with `createUser`, calling `getUserById` with the same ID returns `null` instead of the created user object.

The same symptom affects `updateUser` and `deleteUser` — both silently fail to find the target row.

Expected behaviour: `getUserById(id)` returns the `User` whose `user_id` equals `id`. `updateUser` and `deleteUser` should affect the correct row.

Relevant file: `lib/data/repositories/user_repository.dart`
