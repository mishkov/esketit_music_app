const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { test } = require('node:test');
const { runInNewContext } = require('node:vm');

test('notification click opens its chat before Firebase handles the event', async () => {
  const listeners = [];
  const opened = [];
  let stopped = false;
  let closed = false;
  let completion;
  runInNewContext(readFileSync('web/firebase-messaging-sw.js', 'utf8'), {
    self: { addEventListener: (name, callback) => listeners.push(callback) },
    importScripts: () => {},
    firebase: {
      initializeApp: () => {},
      messaging: () => listeners.push(() => assert.fail('Firebase intercepted the click')),
    },
    clients: { openWindow: async (url) => opened.push(url) },
    encodeURIComponent,
  });
  const event = {
    notification: {
      data: { FCM_MSG: { data: { chatId: 'chat/identifier' } } },
      close: () => { closed = true; },
    },
    stopImmediatePropagation: () => { stopped = true; },
    waitUntil: (promise) => { completion = promise; },
  };
  for (const listener of listeners) {
    listener(event);
    if (stopped) break;
  }
  await completion;
  assert.equal(closed, true);
  assert.deepEqual(opened, ['/agent/chats/chat%2Fidentifier']);
});
