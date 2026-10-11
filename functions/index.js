const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.onNewMessage = functions.firestore
  .document('couples/{coupleId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data) return null;

    const coupleId = context.params.coupleId;
    const senderId = data.senderId;

    // Fetch the couple document to find the partner
    const coupleDoc = await admin.firestore().collection('couples').doc(coupleId).get();
    if (!coupleDoc.exists) return null;
    
    const coupleData = coupleDoc.data();
    
    let receiverId = null;
    let actualSenderId = null;

    if (senderId === 'system') {
      // For system messages, figure out who triggered it based on the timestamp or we just send it to both?
      // Wait, if it's a system message, the app writes it. How do we know who to notify?
      // Actually, if we send it to BOTH, the sender will get a notification.
      // To prevent this, we should look at who wrote the love board note. But the message itself just says "senderId: system".
      // Let's modify the Flutter app's postLoveBoardNote to include `realSenderId` in the system message!
      if (!data.realSenderId) return null; // We will add realSenderId in Flutter
      actualSenderId = data.realSenderId;
      receiverId = coupleData.user1 === actualSenderId ? coupleData.user2 : coupleData.user1;
    } else {
      actualSenderId = senderId;
      receiverId = coupleData.user1 === actualSenderId ? coupleData.user2 : coupleData.user1;
    }

    if (!receiverId || !actualSenderId) return null;

    // Get receiver's FCM token
    const receiverDoc = await admin.firestore().collection('users').doc(receiverId).get();
    if (!receiverDoc.exists) return null;
    const receiverData = receiverDoc.data();
    const fcmToken = receiverData.fcmToken;
    if (!fcmToken) return null;

    // Get sender's name
    const senderDoc = await admin.firestore().collection('users').doc(actualSenderId).get();
    const senderName = senderDoc.exists ? (senderDoc.data().name || 'Your partner') : 'Your partner';

    let title = '';
    let body = '';

    if (senderId === 'system') {
      title = '💌 New Love Letter';
      body = data.text || `${senderName} just posted a letter.`;
    } else if (data.type === 'image') {
      title = `📸 ${senderName} sent a photo`;
      body = 'Tap to view';
    } else if (data.type === 'video') {
      title = `🎥 ${senderName} sent a video`;
      body = 'Tap to view';
    } else {
      title = `💬 New message from ${senderName}`;
      body = data.text && data.text.length > 50 ? data.text.substring(0, 50) + '...' : (data.text || '');
    }

    let msgType = 'chat';
    if (senderId === 'system' || data.type === 'love_board_post') {
      msgType = 'memo';
    }

    const payload = {
      notification: {
        title: title,
        body: body,
        sound: 'default',
      },
      data: {
        type: msgType,
        chatId: coupleId,
        senderId: actualSenderId,
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'loveplus_alerts',
          sound: 'default',
        }
      }
    };

    try {
      await admin.messaging().sendToDevice(fcmToken, payload);
    } catch (e) {
      console.error('Error sending message notification:', e);
    }
    return null;
  });

exports.onNewOotd = functions.firestore
  .document('couples/{coupleId}/ootd/{uid}')
  .onWrite(async (change, context) => {
    // Only trigger on create or if timestamp changed (new upload today)
    if (!change.after.exists) return null;
    const beforeData = change.before.data();
    const afterData = change.after.data();

    // Check if it's a new post (hypeCount changes shouldn't trigger this)
    if (beforeData && beforeData.timestamp && afterData.timestamp && beforeData.timestamp.isEqual(afterData.timestamp)) {
       return null;
    }

    const coupleId = context.params.coupleId;
    const senderId = context.params.uid;

    const coupleDoc = await admin.firestore().collection('couples').doc(coupleId).get();
    if (!coupleDoc.exists) return null;
    
    const coupleData = coupleDoc.data();
    const receiverId = coupleData.user1 === senderId ? coupleData.user2 : coupleData.user1;

    if (!receiverId) return null;

    const receiverDoc = await admin.firestore().collection('users').doc(receiverId).get();
    if (!receiverDoc.exists) return null;
    const receiverData = receiverDoc.data();
    const fcmToken = receiverData.fcmToken;
    if (!fcmToken) return null;

    const senderDoc = await admin.firestore().collection('users').doc(senderId).get();
    const senderName = senderDoc.exists ? (senderDoc.data().name || 'Your partner') : 'Your partner';

    const payload = {
      notification: {
        title: '👕 New Outfit of the Day!',
        body: `${senderName} just posted their OOTD. Tap to check it out!`,
        sound: 'default',
      },
      data: {
        type: 'ootd',
        chatId: coupleId,
        senderId: senderId,
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'loveplus_alerts',
          sound: 'default',
        }
      }
    };

    try {
      await admin.messaging().sendToDevice(fcmToken, payload);
    } catch (e) {
      console.error('Error sending OOTD notification:', e);
    }
    return null;
  });

exports.onNotificationQueue = functions.firestore
  .document('notifications_queue/{id}')
  .onCreate(async (snap) => {
    const data = snap.data();
    if (!data || !data.toToken) return null;

    const payload = {
      notification: {
        title: data.notification?.title || data.title || 'Love Plus Alert',
        body: data.notification?.body || data.body || '',
        sound: 'default',
      },
      data: {
        type: String(data.data?.type || data.type || 'chat'),
        chatId: String(data.data?.chatId || data.coupleId || ''),
        senderId: String(data.data?.senderId || data.senderId || ''),
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'loveplus_alerts',
          sound: 'default',
        }
      }
    };

    try {
      await admin.messaging().sendToDevice(data.toToken, payload);
    } catch (e) {
      console.error('Error delivering queued notification:', e);
    }
    return null;
  });
