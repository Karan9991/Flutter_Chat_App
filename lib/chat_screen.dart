// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class ChatScreen extends StatefulWidget {
//   final String senderId;
//   final String receiverId;

//   ChatScreen({required this.senderId, required this.receiverId});

//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   late TextEditingController _messageController;
//   late CollectionReference _messagesCollection;

//   @override
//   void initState() {
//     super.initState();
//     _messageController = TextEditingController();
//     _messagesCollection = FirebaseFirestore.instance.collection('messages');
//   }

//   void _sendMessage(String message) {
//     _messagesCollection.add({
//       'senderId': widget.senderId,
//       'receiverId': widget.receiverId,
//       'timestamp': Timestamp.now(),
//       'message': message,
//     });

//     _messageController.clear();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Chat Screen'),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//   stream: _messagesCollection
//     .where('senderId', isEqualTo: widget.senderId)
//     .where('receiverId', isEqualTo: widget.receiverId)
//     .orderBy('timestamp', descending: true)
//     .snapshots(),
//   builder: (context, snapshot) {
//     if (!snapshot.hasData) {
//       return Center(
//         child: CircularProgressIndicator(),
//       );
//     }

//     final senderMessages = snapshot.data!.docs;

//     return StreamBuilder<QuerySnapshot>(
//       stream: _messagesCollection
//         .where('senderId', isEqualTo: widget.receiverId)
//         .where('receiverId', isEqualTo: widget.senderId)
//         .orderBy('timestamp', descending: true)
//         .snapshots(),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) {
//           return Center(
//             child: CircularProgressIndicator(),
//           );
//         }

//         final receiverMessages = snapshot.data!.docs;
//         final allMessages = [...senderMessages, ...receiverMessages];
//         allMessages.sort(
//           (a, b) => a['timestamp'].compareTo(b['timestamp']),
//         );

//         return ListView.builder(
//           reverse: true,
//           itemCount: allMessages.length,
//           itemBuilder: (context, index) {
//             final message = allMessages[index];
//             final messageText = message['message'] ?? '';

//             return ListTile(
//               title: Text(messageText),
//               subtitle: Text(message['timestamp'].toString()),
//               trailing: Text(message['senderId']),
//             );
//           },
//         );
//       },
//     );
//   },
// ),

//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _messageController,
//                     decoration: InputDecoration(
//                       hintText: 'Type a message',
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.send),
//                   onPressed: () {
//                     _sendMessage(_messageController.text.trim());
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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

  final RxList<ChatMessage> _messages = <ChatMessage>[].obs;

  List<ChatMessage> get messages => _messages;

  @override
  void onInit() {
    super.onInit();
    _subscribeToChat();
    _configureFCM();
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
      print("fffffffffffforeground notifications");
      // Handle foreground notifications here
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle background notifications here
      print("bbbbbbbbbbbbbackground notifications");
    });
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
//  RECEIVER_USER_ID   SENDER_USER_ID