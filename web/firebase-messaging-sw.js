importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyAEMpbAgB5Ly3DZV9wGW0RYoIgO5J6N-xU",
  authDomain: "kidtang-97499.firebaseapp.com",
  projectId: "kidtang-97499",
  storageBucket: "kidtang-97499.firebasestorage.app",
  messagingSenderId: "971449413886",
  appId: "1:971449413886:web:905921f29bcb2fd51ab5af",
  measurementId: "G-1SR9G7H0VR"
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);

  const notificationTitle = payload.notification?.title || 'KidTang';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data,
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});
