// web/firebase-messaging-sw.js

importScripts('https://www.gstatic.com/firebasejs/9.10.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.10.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDJWzJRqvOHvoYwcMTL6jAhFCMj2bsFZDE',
  appId: '1:435533952242:web:04543221ec2b0cb7004c6b',
  messagingSenderId: '435533952242',
  projectId: 'piv-fertilizer-app',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
