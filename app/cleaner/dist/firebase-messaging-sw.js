importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

firebase.initializeApp({
    apiKey: "AIzaSyAwJq6jz0RHEB9Dqm9LqYJYssARi7Semh0",
    authDomain: "jnn-crm.firebaseapp.com",
    projectId: "jnn-crm",
    storageBucket: "jnn-crm.firebasestorage.app",
    messagingSenderId: "659587303892",
    appId: "1:659587303892:web:a88a9e6128128472582e41"
});

const messaging = firebase.messaging();

// Xử lý tin nhắn khi app ở background
messaging.onBackgroundMessage((payload) => {
    console.log('Received background message:', payload);

    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
        icon: '/logo192.png'
    };

    self.registration.showNotification(notificationTitle, notificationOptions);
}); 