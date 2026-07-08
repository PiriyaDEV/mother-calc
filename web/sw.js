// Kidtang Web Push Service Worker
// Handles background push notifications via the Web Push API (VAPID).

self.addEventListener('push', function (event) {
  if (!event.data) return;

  let payload;
  try {
    payload = event.data.json();
  } catch (_) {
    payload = { title: 'Kidtang!', body: event.data.text() };
  }

  const title = payload.title || 'Kidtang!';
  const options = {
    body: payload.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data || {},
    tag: payload.tag || 'kidtang-push',
    renotify: true,
  };

  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  event.waitUntil(
    clients
      .matchAll({ type: 'window', includeUncontrolled: true })
      .then(function (clientList) {
        // Focus existing tab if open
        for (const client of clientList) {
          if ('focus' in client) return client.focus();
        }
        // Otherwise open a new tab
        if (clients.openWindow) return clients.openWindow('/');
      }),
  );
});
