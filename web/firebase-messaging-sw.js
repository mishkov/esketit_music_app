// Register before Firebase installs its default notification-click handler.
self.addEventListener('notificationclick', (event) => {
  const identifier = event.notification.data?.FCM_MSG?.data?.chatId;
  if (!identifier) return;
  event.stopImmediatePropagation();
  event.notification.close();
  event.waitUntil(clients.openWindow(`/agent/chats/${encodeURIComponent(identifier)}`));
});

/* Public Firebase configuration is deployed beside this worker. */
importScripts('firebase-config.js');
importScripts('https://www.gstatic.com/firebasejs/13.1.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/13.1.0/firebase-messaging-compat.js');

firebase.initializeApp(self.esketitFirebaseConfiguration);
firebase.messaging();
