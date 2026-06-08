// web/firebase-messaging-sw.js

importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDJWzJRqvOHvoYwcMTL6jAhFCMj2bsFZDE',
  appId: '1:435533952242:web:04543221ec2b0cb7004c6b',
  messagingSenderId: '435533952242',
  projectId: 'piv-fertilizer-app',
  authDomain: 'piv-fertilizer-app.firebaseapp.com',
  storageBucket: 'piv-fertilizer-app.firebasestorage.app',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);

  const notificationTitle = payload.notification?.title || 'Thông báo PIV';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png'
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});
