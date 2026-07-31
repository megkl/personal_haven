const test = require("node:test");
const {after, before, beforeEach} = require("node:test");
const fs = require("node:fs");
const path = require("node:path");
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "personal-haven-rules-test",
    firestore: {
      rules: fs.readFileSync(
          path.resolve(__dirname, "../../firestore.rules"),
          "utf8",
      ),
    },
  });
});

beforeEach(async () => testEnv.clearFirestore());
after(async () => testEnv.cleanup());

/**
 * Builds a valid user profile fixture.
 * @param {string} uid User ID.
 * @param {boolean} isPremium Premium field value.
 * @return {object} Firestore profile data.
 */
function profile(uid, isPremium = false) {
  return {
    user_id: uid,
    email: `${uid}@example.com`,
    username: null,
    firstName: "Test",
    lastName: "User",
    avatarUrl: null,
    bio: null,
    createdAt: "2026-07-22T00:00:00.000Z",
    lastLoginAt: null,
    isPremium,
    preferences: null,
  };
}

/**
 * Builds a valid task fixture.
 * @param {string} uid User ID.
 * @param {string} id Document ID.
 * @return {object} Firestore task data.
 */
function taskDocument(uid, id) {
  return {
    id,
    userId: uid,
    title: "A valid task",
    description: null,
    isCompleted: false,
    dueDate: null,
    priority: "medium",
    category: "personal",
    createdAt: "2026-07-22T00:00:00.000Z",
    completedAt: null,
  };
}

test("denies unauthenticated and cross-user reads", async () => {
  const owner = testEnv.authenticatedContext("owner").firestore();
  await assertSucceeds(owner.doc("users/owner").set(profile("owner")));

  await assertFails(
      testEnv.unauthenticatedContext().firestore().doc("users/owner").get(),
  );
  await assertFails(
      testEnv.authenticatedContext("attacker").firestore()
          .doc("users/owner").get(),
  );
});

test("prevents clients from granting or changing premium", async () => {
  const db = testEnv.authenticatedContext("owner").firestore();
  await assertFails(db.doc("users/owner").set(profile("owner", true)));
  await assertSucceeds(db.doc("users/owner").set(profile("owner")));
  await assertFails(db.doc("users/owner").update({isPremium: true}));
  await assertFails(db.doc("users/owner").update({trialUsed: true}));
});

test("allows owner records and rejects forged fields", async () => {
  const db = testEnv.authenticatedContext("owner").firestore();
  await assertSucceeds(db.doc("users/owner").set(profile("owner")));
  await assertSucceeds(
      db.doc("users/owner/tasks/task-1")
          .set(taskDocument("owner", "task-1")),
  );
  await assertFails(
      db.doc("users/owner/tasks/task-2")
          .set({...taskDocument("attacker", "task-2"), admin: true}),
  );
});

test("makes subscriptions server-only", async () => {
  const db = testEnv.authenticatedContext("owner").firestore();
  await assertSucceeds(db.doc("users/owner").set(profile("owner")));
  await assertFails(db.doc("users/owner/subscriptions/fake").set({
    status: "active",
    expiryDate: "2099-01-01T00:00:00.000Z",
  }));
});

test("makes chat history owner-readable and server-writable only", async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc("users/owner/chats/message-1").set({
      role: "assistant",
      content: "Choose one small next step.",
      createdAt: new Date("2026-07-31T10:00:00.000Z"),
    });
  });

  const owner = testEnv.authenticatedContext("owner").firestore();
  const attacker = testEnv.authenticatedContext("attacker").firestore();
  await assertSucceeds(
      owner.doc("users/owner/chats/message-1").get(),
  );
  await assertFails(
      attacker.doc("users/owner/chats/message-1").get(),
  );
  await assertFails(
      owner.doc("users/owner/chats/message-2").set({
        role: "user",
        content: "Client-side forged message",
      }),
  );
});
