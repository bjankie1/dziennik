// EduSync (Lepsza Szkoła) - Service Worker dla powiadomień Web Push (Phase 18)
self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

// Obsługa natywnych zdarzeń Push (VAPID / FCM / Web Push)
self.addEventListener('push', (event) => {
  let payload = {
    title: 'EduSync • Lepsza Szkoła',
    body: 'Nowe zdarzenie w dzienniku szkolnym',
    icon: '/icons/Icon-192.png',
    badge: '/favicon.png',
    tag: 'edusync-notification',
    url: '/pulpit',
  };

  if (event.data) {
    try {
      const parsed = event.data.json();
      payload = { ...payload, ...parsed };
    } catch (e) {
      payload.body = event.data.text();
    }
  }

  const options = {
    body: payload.body,
    icon: payload.icon || '/icons/Icon-192.png',
    badge: payload.badge || '/favicon.png',
    tag: payload.tag || `edusync-${Date.now()}`,
    renotify: true,
    data: {
      url: payload.url || '/pulpit',
    },
  };

  event.waitUntil(self.registration.showNotification(payload.title, options));
});

// Komunikacja z aplikacją Flutter Web do wywoływania powiadomień przez Service Worker
self.addEventListener('message', (event) => {
  if (!event.data || event.data.type !== 'SHOW_NOTIFICATION') return;

  const { title, body, tag, url } = event.data;
  const options = {
    body: body || '',
    icon: '/icons/Icon-192.png',
    badge: '/favicon.png',
    tag: tag || `edusync-${Date.now()}`,
    renotify: true,
    data: {
      url: url || '/pulpit',
    },
  };

  event.waitUntil(
    self.registration.showNotification(title || 'EduSync • Lepsza Szkoła', options)
  );
});

// Kliknięcie w powiadomienie otwiera lub aktywuje odpowiednią zakładkę w aplikacji
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const targetUrl = (event.notification.data && event.notification.data.url) || '/pulpit';

  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if ('focus' in client) {
          client.focus();
          if ('navigate' in client && targetUrl) {
            client.navigate(targetUrl).catch(() => {});
          }
          return;
        }
      }
      if (self.clients.openWindow) {
        return self.clients.openWindow(targetUrl);
      }
    })
  );
});
