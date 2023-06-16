import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final int timestamp;
  final String message;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.timestamp,
    required this.message,
  });
}

class ChatController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final RxList<ChatMessage> _messages = <ChatMessage>[].obs;

  List<ChatMessage> get messages => _messages;

  @override
  void onInit() {
    super.onInit();
    _subscribeToChat();
    //   _configureFCM();
    print('iiiiiiiiinit');
  }

  void _subscribeToChat() {
    _firestore
        .collection('chats')
        .doc('YOUR_CHAT_ID')
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      final messages = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ChatMessage(
          id: doc.id,
          senderId: data['senderId'],
          receiverId: data['receiverId'],
          timestamp: data['timestamp'],
          message: data['message'],
        );
      }).toList();
      _messages.assignAll(messages);
    });
  }

  void _configureFCM() {
    _firebaseMessaging.requestPermission();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('fffffffffForeground notification received');
      // Handle foreground notifications here
      // Example: Show a local notification using flutter_local_notifications package
      _showLocalNotification(message.data);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('bbbbbbbbbbbBackground notification received');
      // Handle background notifications here
    });
  }

  void _showLocalNotification(Map<String, dynamic> data) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      channelDescription: 'channel_description',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      data['title'] ?? '',
      data['body'] ?? '',
      platformChannelSpecifics,
      payload: data['payload'],
    );
  }

  Future<void> sendMessage(
      String senderId, String receiverId, String message) async {
    final chatRef = _firestore.collection('chats').doc('YOUR_CHAT_ID');
    final messageRef = chatRef.collection('messages').doc();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final messageData = {
      'id': messageRef.id,
      'senderId': senderId,
      'receiverId': receiverId,
      'timestamp': timestamp,
      'message': message,
    };

    await messageRef.set(messageData);

    // Retrieve the receiver's FCM token
    //change senderid and receiver id here
    final receiverFCMToken = await getReceiverFCMToken(receiverId);

    // Send notification to the receiver
    await sendNotificationToReceiver(
        receiverFCMToken ?? '', senderId, receiverId, message);
  }

  Future<String?> getReceiverFCMToken(String receiverUserId) async {
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(receiverUserId);
    final userSnapshot = await userRef.get();

    if (userSnapshot.exists) {
      // FCM token exists in the database, retrieve and return it
      return userSnapshot.data()?['fcmToken'];
    } else {
      // FCM token doesn't exist in the database, generate a new token and store it
      final receiverFCMToken = await FirebaseMessaging.instance.getToken();

      if (receiverFCMToken != null) {
        print("rrrrrrrrreceiverFCMToken");
        print(receiverFCMToken);
        // Save the FCM token in the database for future use
        await userRef.set({'fcmToken': receiverFCMToken});
      }

      return receiverFCMToken;
    }
  }

  Future<void> sendNotificationToReceiver(String receiverFCMToken,
      String senderId, String receiverId, String message) async {
    print('receiver token $receiverFCMToken');
    // Replace 'YOUR_SERVER_KEY' with your FCM server key
    String serverKey =
        'AAAA51Dk8wU:APA91bH16JrFM6yg3w014AeQ77SmXCjaTCiT8XlRy3CKPhv79XZx7xVV1_SpzLMsGaG1Zal9Cjr9gBhdMVDwz7Ka4-nnKMRyCLx2hWwoec3VahSQ5aEWxDJkqPbLkebovTWdCgkdSFTB';
    String url = 'https://fcm.googleapis.com/fcm/send';

    // Replace 'YOUR_NOTIFICATION_TITLE' and 'YOUR_NOTIFICATION_BODY' with your desired notification title and body
    String notificationTitle = 'New Message $message';
    String notificationBody = 'You have received a new message from $senderId';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(<String, dynamic>{
          'notification': <String, dynamic>{
            'body': notificationBody,
            'title': notificationTitle,
          },
          'priority': 'high',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'senderUserId': senderId,
            'receiverUserId': receiverId,
          },
          'to': receiverFCMToken,
        }),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully');
      } else {
        print(
            'Failed to send notification. StatusCode: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to send notification. Error: $e');
    }
  }
}

class ChatScreen extends StatelessWidget {
  final ChatController _chatController = Get.put(ChatController());

  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Screen'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(
              () => ListView.builder(
                itemCount: _chatController.messages.length,
                reverse: true,
                itemBuilder: (context, index) {
                  final message = _chatController.messages[index];
                  final isSender = message.senderId ==
                      'SENDER_USER_ID'; // Replace 'SENDER_USER_ID' with the actual sender user ID

                  return Align(
                    alignment:
                        isSender ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSender ? Colors.blue[200] : Colors.grey[300],
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(isSender ? 16 : 0),
                          topRight: Radius.circular(isSender ? 0 : 16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Text(
                        message.message,
                        style: TextStyle(
                          color: isSender ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your messagee...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    final senderId = 'SENDER_USER_ID';
                    final receiverId = 'RECEIVER_USER_ID';
                    final message = _messageController.text.trim();
                    _chatController.sendMessage(senderId, receiverId, message);
                    _messageController.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// RECEIVER_USER_ID   SENDER_USER_ID
