import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/notification_service.dart';

class ChatTheme {
  final String id;
  final String name;
  final String emoji;
  final List<Color> backgroundColors;
  final List<Color> userBubbleColors;
  final List<Color> partnerBubbleColors;
  final Color userTextColor;
  final Color partnerTextColor;
  final Color? partnerBorderColor;
  final Color userShadowColor;
  final Color accentColor;

  const ChatTheme({
    required this.id,
    required this.name,
    required this.emoji,
    required this.backgroundColors,
    required this.userBubbleColors,
    required this.partnerBubbleColors,
    this.userTextColor = Colors.white,
    this.partnerTextColor = Colors.black87,
    this.partnerBorderColor,
    this.userShadowColor = Colors.black12,
    this.accentColor = const Color(0xFFE295B4),
  });
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final String? type;
  final String? replyingToText;
  final String? imageUrl;
  final String? senderAvatar;
  final DateTime timestamp;
  final String? realSenderId;
  final String? purpose;
  bool isLiked;
  bool isRead;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.type,
    this.replyingToText,
    this.imageUrl,
    this.senderAvatar,
    this.isLiked = false,
    this.isRead = false,
    this.realSenderId,
    this.purpose,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AppState extends ChangeNotifier {
  AppState() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeId = prefs.getString('chatThemeId');
    if (themeId != null) {
      try {
        chatTheme = availableThemes.firstWhere((t) => t.id == themeId);
        notifyListeners();
      } catch (e) {
        // ignore
      }
    }
  }
  bool isLinked = false;
  String? userName;
  String? partnerName;
  String? connectionCode;
  String? userRole; // "BF" or "GF"
  
  String? userOotdImage;
  String? partnerOotdImage;

  int _currentCoins = 1000;
  int get currentCoins => _currentCoins;

  int userGameScore = 0;
  int partnerGameScore = 0;
  DateTime? lastPlayedHowWell;

  void addGamePoints(int points, {required bool isUser}) {
    if (isUser) {
      userGameScore += points;
      if (currentCoupleId != null && currentUid != null) {
        FirebaseFirestore.instance.collection('couples').doc(currentCoupleId).set({
          'score_$currentUid': userGameScore,
        }, SetOptions(merge: true));
      }
    } else {
      partnerGameScore += points;
    }
    notifyListeners();
  }

  void markHowWellPlayed() {
    lastPlayedHowWell = DateTime.now();
    notifyListeners();
  }

  DateTime? lastPlayedScenarioScale;

  void markScenarioScalePlayed() {
    lastPlayedScenarioScale = DateTime.now();
    notifyListeners();
  }

  DateTime? lastPlayedTicTacToe;

  void markTicTacToePlayed() {
    lastPlayedTicTacToe = DateTime.now();
    notifyListeners();
  }

  DateTime? lastPlayedHowMad;

  void markHowMadPlayed() {
    lastPlayedHowMad = DateTime.now();
    notifyListeners();
  }

  DateTime? lastPlayedExposeUs;

  void markExposeUsPlayed() {
    lastPlayedExposeUs = DateTime.now();
    notifyListeners();
  }

  String? currentUid;
  String? currentCoupleId;
  StreamSubscription? _messagesSub;

  StreamSubscription<DocumentSnapshot>? _userDocSub;
  
  void listenToUserDoc(String uid) {
    if (currentUid == uid && _userDocSub != null) return;
    _userDocSub?.cancel();
    _userDocSub = FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((doc) {
      if (doc.exists) {
        syncUserFromFirestore(uid, doc.data() as Map<String, dynamic>);
      }
    });
  }

  void syncUserFromFirestore(String uid, Map<String, dynamic> data) {
    bool changed = false;
    if (currentUid != uid) {
      currentUid = uid;
      changed = true;
    }
    
    if (userName != data['name']) {
      userName = data['name'];
      changed = true;
    }
    if (userRole != data['role']) {
      userRole = data['role'];
      changed = true;
    }
    if (connectionCode != data['connectionCode']) {
      connectionCode = data['connectionCode'];
      changed = true;
    }
    
    final bool newReadReceipts = data['readReceiptsEnabled'] ?? true;
    if (readReceiptsEnabled != newReadReceipts) {
      readReceiptsEnabled = newReadReceipts;
      changed = true;
    }
    
    final coupleId = data['coupleId'];
    if (coupleId != null && coupleId != currentCoupleId) {
      currentCoupleId = coupleId;
      isLinked = true;
      partnerName = data['partnerName'] ?? "Lover"; 
      _listenToMessages(coupleId);
      _listenToCoupleData(coupleId);
      _listenToChallenges(coupleId);
      changed = true;
    }
    
    if (changed) {
      notifyListeners();
    }
  }

  StreamSubscription? _coupleSub;
  StreamSubscription? _challengesSub;
  bool isPartnerTyping = false;
  bool readReceiptsEnabled = true;

  void _listenToCoupleData(String coupleId) {
    _coupleSub?.cancel();
    _coupleSub = FirebaseFirestore.instance.collection('couples').doc(coupleId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        final partnerUid = currentUid == data['user1'] ? data['user2'] : data['user1'];
        final newIsTyping = data['typing_$partnerUid'] ?? false;
        
        if (isPartnerTyping != newIsTyping) {
          isPartnerTyping = newIsTyping;
          notifyListeners();
        }
        
        final newMyScore = data['score_$currentUid'] ?? 0;
        final newPartnerScore = data['score_$partnerUid'] ?? 0;
        if (userGameScore != newMyScore || partnerGameScore != newPartnerScore) {
          userGameScore = newMyScore as int;
          partnerGameScore = newPartnerScore as int;
          notifyListeners();
        }
      }
    });
  }

  void _listenToMessages(String coupleId) {
    _messagesSub?.cancel();
    _messagesSub = FirebaseFirestore.instance
      .collection('couples')
      .doc(coupleId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .listen((snapshot) {
        messages = snapshot.docs.map((doc) {
          final d = doc.data();
            return ChatMessage(
              id: doc.id,
              text: d['text'] ?? '',
              isUser: d['senderId'] == currentUid,
              timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
              type: d['type'],
              replyingToText: d['replyingToText'],
              imageUrl: d['imageUrl'],
              isLiked: d['isLiked'] ?? false,
              isRead: d['isRead'] ?? false,
              realSenderId: d['realSenderId'],
              purpose: d['purpose'],
            );
        }).toList();
        notifyListeners();
    });
  }

  Future<void> setUserRole(String role) async {
    userRole = role;
    notifyListeners();
    if (currentUid != null) {
      await FirebaseFirestore.instance.collection('users').doc(currentUid).update({'role': role});
    }
  }

  Future<void> setUserName(String name) async {
    userName = name;
    notifyListeners();
    if (currentUid != null) {
      await FirebaseFirestore.instance.collection('users').doc(currentUid).update({'name': name});
    }
  }

  Future<void> generateCode() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? currentUid;
      if (uid == null) {
        print('Generate Code Error: User ID is null');
        return;
      }
      
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final rnd = Random();
      final code = String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
      
      // Ensure the generated code is actually being saved to Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({'connectionCode': code}, SetOptions(merge: true)).timeout(const Duration(seconds: 5));
      
      // Successfully generated and saved, now assign to state variable and update UI
      currentUid = uid;
      connectionCode = code;
      notifyListeners();
    } catch (e) {
      print('Generate Code Error: $e');
      rethrow;
    }
  }

  Future<void> linkWithPartner(String code, [String? pName]) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('Authentication error: Please sign out and sign back in.');
    final currentUserId = currentUser.uid;
    
    final safeCode = code.trim().toUpperCase();
    
    final query = await FirebaseFirestore.instance.collection('users').where('connectionCode', isEqualTo: safeCode).limit(1).get();
    
    if (query.docs.isEmpty) throw Exception('Invalid connection code. Partner not found.');
    
    final partnerDoc = query.docs.first;
    final partnerUid = partnerDoc.id;
    
    if (partnerUid == currentUserId) throw Exception('You cannot link with your own code.');
    
    final pData = partnerDoc.data();
    if (pData['coupleId'] != null) throw Exception('Partner is already linked!');
    
    final uids = [currentUserId, partnerUid]..sort();
    final coupleId = '${uids[0]}_${uids[1]}';
    
    final batch = FirebaseFirestore.instance.batch();
    
    final coupleRef = FirebaseFirestore.instance.collection('couples').doc(coupleId);
    batch.set(coupleRef, {
      'user1': uids[0],
      'user2': uids[1],
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    final myRef = FirebaseFirestore.instance.collection('users').doc(currentUserId);
    batch.update(myRef, {
      'coupleId': coupleId,
      'partnerName': pName ?? "Lover",
      'partnerId': partnerUid,
      'linkedPartnerUid': partnerUid,
    });
    
    final pRef = FirebaseFirestore.instance.collection('users').doc(partnerUid);
    batch.update(pRef, {
      'coupleId': coupleId,
      'partnerName': userName ?? "Lover", 
      'partnerId': currentUserId,
      'linkedPartnerUid': currentUserId,
    });
    
    await batch.commit();
  }

  Future<void> enterDemoMode() async {
    if (currentUid == null) return;
    
    final partnerUid = 'demo_partner_${Random().nextInt(10000)}';
    final uids = [currentUid!, partnerUid]..sort();
    final coupleId = '${uids[0]}_${uids[1]}';
    
    final batch = FirebaseFirestore.instance.batch();
    
    final coupleRef = FirebaseFirestore.instance.collection('couples').doc(coupleId);
    batch.set(coupleRef, {
      'user1': uids[0],
      'user2': uids[1],
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    final myRef = FirebaseFirestore.instance.collection('users').doc(currentUid);
    batch.update(myRef, {
      'coupleId': coupleId,
      'partnerName': "Demo Partner",
      'linkedPartnerUid': partnerUid,
      if (userName == null) 'name': 'Me',
      if (userRole == null) 'role': 'BF',
    });
    
    await batch.commit();
  }

  void setUserOotdImage(String url) {
    userOotdImage = url;
    notifyListeners();
  }

  Future<void> uploadOotdImage(File image) async {
    if (currentCoupleId == null || currentUid == null) return;
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '$timestamp.jpg';
    final path = 'ootd/$currentCoupleId/$currentUid/$fileName';
    final ref = FirebaseStorage.instance.ref().child(path);
    
    final fileBytes = await image.readAsBytes();
    final uploadTask = await ref.putData(
      fileBytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final url = await uploadTask.ref.getDownloadURL();
    
    await FirebaseFirestore.instance
      .collection('couples')
      .doc(currentCoupleId)
      .collection('ootd')
      .doc(currentUid)
      .set({
        'imageUrl': url,
        'timestamp': FieldValue.serverTimestamp(),
        'hypeCount': 0,
      }, SetOptions(merge: true));
  }

  Future<void> incrementHype(String targetUid) async {
    if (currentCoupleId == null) return;
    await FirebaseFirestore.instance
      .collection('couples')
      .doc(currentCoupleId)
      .collection('ootd')
      .doc(targetUid)
      .update({
        'hypeCount': FieldValue.increment(1),
      });
  }
  
  void spendCoins(int amount) {
    if (_currentCoins >= amount) {
      _currentCoins -= amount;
      notifyListeners();
    }
  }

  ChatTheme? chatTheme;

  void setChatTheme(ChatTheme? theme) async {
    chatTheme = theme;
    notifyListeners();
    if (theme != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('chatThemeId', theme.id);
    }
  }

  final List<ChatTheme> availableThemes = [
    const ChatTheme(
      id: 'sunset_aurora',
      name: 'Sunset Aurora',
      emoji: '🌅',
      backgroundColors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
      userBubbleColors: [Color(0xFFFF7E5F), Color(0xFFFEB47B)],
      partnerBubbleColors: [Color(0x33FF7E5F), Color(0x33FEB47B)],
      userTextColor: Colors.white,
      partnerTextColor: Colors.white,
      partnerBorderColor: Color(0x55FF7E5F),
      userShadowColor: Color(0xFFFFD700),
      accentColor: Color(0xFFFFD700),
    ),
    const ChatTheme(
      id: 'enchanted_sakura',
      name: 'Enchanted Sakura',
      emoji: '🌸',
      backgroundColors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
      userBubbleColors: [Color(0x88FFB7B2), Color(0x88FF9A9E)],
      partnerBubbleColors: [Color(0x18FFFFFF), Color(0x18FFFFFF)],
      userTextColor: Colors.white,
      partnerTextColor: Colors.white,
      partnerBorderColor: Color(0x88FFB7B2),
      userShadowColor: Color(0xFFFF9A9E),
      accentColor: Color(0xFFFF9A9E),
    ),
    const ChatTheme(
      id: 'cyber_bloom',
      name: 'Cyber Bloom',
      emoji: '⚡',
      backgroundColors: [Color(0xFF000000), Color(0xFF0A0A0A)],
      userBubbleColors: [Color(0x33FF007F), Color(0x3300FFFF)],
      partnerBubbleColors: [Color(0x11FFFFFF), Color(0x11FFFFFF)],
      userTextColor: Colors.white,
      partnerTextColor: Colors.white,
      partnerBorderColor: Color(0x8800FFFF),
      userShadowColor: Color(0xFFFF007F),
      accentColor: Color(0xFF00FFFF),
    ),
  ];

  List<ChatMessage> messages = [];
  
  int get unreadCount => messages.where((m) => !m.isUser && !m.isRead).length;

  void addMessage(ChatMessage message) {
    if (currentCoupleId == null || currentUid == null) return;
    
    FirebaseFirestore.instance
      .collection('couples')
      .doc(currentCoupleId)
      .collection('messages')
      .add({
        'text': message.text,
        'senderId': currentUid,
        'timestamp': FieldValue.serverTimestamp(),
        'type': message.type,
        'replyingToText': message.replyingToText,
        'imageUrl': message.imageUrl,
        'isLiked': message.isLiked,
      });
  }

  void toggleLike(String messageId) {
    if (currentCoupleId == null) return;
    
    var msg = messages.firstWhere((m) => m.id == messageId, orElse: () => messages.first);
    final newLikeState = !msg.isLiked;
    
    FirebaseFirestore.instance
      .collection('couples')
      .doc(currentCoupleId)
      .collection('messages')
      .doc(messageId)
      .update({'isLiked': newLikeState});
      
    if (newLikeState) {
      // Trigger a cloud function/FCM payload here
      debugPrint("FCM STUB: PUSH NOTIFICATION -> 'Your partner loved your message!'");
    }
  }

  Future<void> setTypingStatus(bool isTyping) async {
    if (currentCoupleId == null || currentUid == null) return;
    await FirebaseFirestore.instance.collection('couples').doc(currentCoupleId).update({
      'typing_$currentUid': isTyping,
    });
  }

  Future<void> markMessagesAsRead() async {
    if (currentCoupleId == null || currentUid == null) return;
    
    final unreadMessages = messages.where((m) => !m.isUser && !m.isRead).toList();
    if (unreadMessages.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (var msg in unreadMessages) {
      final ref = FirebaseFirestore.instance
          .collection('couples')
          .doc(currentCoupleId)
          .collection('messages')
          .doc(msg.id);
      batch.update(ref, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> toggleReadReceipts(bool enabled) async {
    if (currentUid == null) return;
    readReceiptsEnabled = enabled;
    notifyListeners();
    await FirebaseFirestore.instance.collection('users').doc(currentUid).update({
      'readReceiptsEnabled': enabled,
    });
  }

  Future<void> updateLocation(double lat, double lng, String city) async {
    if (currentCoupleId == null || currentUid == null) return;
    
    await FirebaseFirestore.instance.collection('couples').doc(currentCoupleId).set({
      'locations': {
        currentUid!: {
          'lat': lat,
          'lng': lng,
          'city': city,
          'timestamp': FieldValue.serverTimestamp(),
        }
      }
    }, SetOptions(merge: true));
  }

  // Pending challenges for games
  List<Map<String, dynamic>> pendingChallenges = [];

  void _listenToChallenges(String coupleId) {
    _challengesSub?.cancel();
    _challengesSub = FirebaseFirestore.instance
      .collection('couples')
      .doc(coupleId)
      .collection('challenges')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .listen((snapshot) {
        pendingChallenges = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id; // overwrite id to be doc id
          return data;
        }).toList();
        notifyListeners();
      });
  }

  Future<void> addPendingChallenge(Map<String, dynamic> challenge) async {
    if (currentCoupleId == null || currentUid == null) return;
    
    // Convert 'from': 'Partner' local logic to targetId/senderId
    final targetId = challenge['targetId'] ?? (currentUid == currentCoupleId!.split('_')[0] ? currentCoupleId!.split('_')[1] : currentCoupleId!.split('_')[0]);
    
    challenge['senderId'] = currentUid;
    challenge['targetId'] = targetId;
    challenge['status'] = 'pending';
    challenge['timestamp'] = FieldValue.serverTimestamp();

    await FirebaseFirestore.instance
      .collection('couples')
      .doc(currentCoupleId)
      .collection('challenges')
      .add(challenge);
  }

  Future<void> removePendingChallenge(String id) async {
    if (currentCoupleId == null) return;
    
    await FirebaseFirestore.instance
      .collection('couples')
      .doc(currentCoupleId)
      .collection('challenges')
      .doc(id)
      .update({'status': 'completed'});
  }

  // LOVE BOARD FEATURE
  Future<void> requestPushPermissions() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    // Retrieve token if needed: String? token = await messaging.getToken();
  }

  Future<void> postToLoveBoard({
    required String text,
    required String purpose,
    required int colorIndex,
    required bool isGift,
  }) async {
    if (currentCoupleId == null || currentUid == null) return;
    
    final batch = FirebaseFirestore.instance.batch();
    
    // 1. Write to love_board
    final boardRef = FirebaseFirestore.instance
        .collection('couples')
        .doc(currentCoupleId)
        .collection('love_board')
        .doc();
        
    batch.set(boardRef, {
      'text': text,
      'purpose': purpose,
      'colorIndex': colorIndex,
      'isGift': isGift,
      'senderId': currentUid,
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    // 2. Write automated message to chat
    final msgRef = FirebaseFirestore.instance
        .collection('couples')
        .doc(currentCoupleId)
        .collection('messages')
        .doc();
        
    batch.set(msgRef, {
      'senderId': 'system', // Distinguish as a system automated message
      'realSenderId': currentUid,
      'purpose': purpose, // Save the purpose for dynamic rendering
      'text': '', // Handled dynamically in UI
      'type': 'love_board_post',
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    await batch.commit();
    
    // 3. Stub for FCM Push Notification (Client-side simulation)
    print("FCM STUB: Sending push notification to partner with title 'New Love-Board Post' and body 'Your partner just posted a $purpose.'");
    // Normally, here you would call a Cloud Function or FCM HTTP v1 API.
  }

  // GAME INDEX TRACKING
  Future<int> fetchDailyGameIndex(String gameKey, int itemsPerDay) async {
    if (currentCoupleId == null) return 0;
    
    final docRef = FirebaseFirestore.instance.collection('couples').doc(currentCoupleId);
    
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    
    int startIndex = 0;
    
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      
      final data = snapshot.data()!;
      final currentIndex = data['${gameKey}_index'] as int? ?? 0;
      final lastDate = data['${gameKey}_lastDate'] as String?;
      
      if (lastDate != todayStr) {
        startIndex = (lastDate == null) ? 0 : (currentIndex + itemsPerDay);
        transaction.update(docRef, {
          '${gameKey}_lastDate': todayStr,
          '${gameKey}_index': startIndex,
        });
      } else {
        startIndex = currentIndex;
      }
    });
    
    return startIndex;
  }

  // FILE UPLOADS
  Future<String?> uploadImage(File image) async {
    if (currentCoupleId == null) return null;
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
      final ref = FirebaseStorage.instance.ref().child('couples').child(currentCoupleId!).child('images').child(fileName);
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("Error uploading image: $e");
      return null;
    }
  }

  Future<String?> uploadVoiceNote(File audio) async {
    if (currentCoupleId == null) return null;
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString() + '.m4a';
      final ref = FirebaseStorage.instance.ref().child('couples').child(currentCoupleId!).child('audio').child(fileName);
      await ref.putFile(audio);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("Error uploading audio: $e");
      return null;
    }
  }

  // PUSH NOTIFICATIONS & TOKENS
  Future<void> setupFCMToken() async {
    if (currentUid == null) return;
    try {
      final messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission();
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized || settings.authorizationStatus == AuthorizationStatus.provisional) {
        String? token = await messaging.getToken();
        if (token != null) {
          await FirebaseFirestore.instance.collection('users').doc(currentUid).update({'fcmToken': token});
        }
        
        messaging.onTokenRefresh.listen((newToken) {
          FirebaseFirestore.instance.collection('users').doc(currentUid).update({'fcmToken': newToken});
        });
      }
    } catch (e) {
      debugPrint("Error setting up FCM token: $e");
    }
  }
}





