import 'package:firebase_database/firebase_database.dart';

class ChatService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // Send Message
  Future<void> sendMessage(String userId, String message, bool isAdmin, String username) async {
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Message data
    Map<String, dynamic> newMessage = {
      'senderId': isAdmin ? 'admin' : userId,
      'text': message,
      'timestamp': timestamp,
      'isAdmin': isAdmin,
    };

    // Add to messages list under user
    await _dbRef
        .child('chats')
        .child('messages')
        .child(userId)
        .push()
        .set(newMessage);

    // Update summary for Chat List
    Map<String, dynamic> summaryData = {
      'lastMessage': message,
      'lastMessageTime': timestamp,
      'userId': userId,
      'unreadAdmin': !isAdmin, // If user sends, unread for admin
      'unreadUser': isAdmin,   // If admin sends, unread for user
    };

    // Hanya update username jika yang mengirim adalah User (agar nama tidak tertimpa jadi 'Admin')
    if (!isAdmin) {
      summaryData['username'] = username;
    }

    // We use 'update' to merge specific fields if exist, but for RTDB strict structure is better.
    // However, here we want to ensure username persists or updates.
    await _dbRef.child('chats').child('summaries').child(userId).update(summaryData);
  }

  // Get Messages Stream
  Stream<DatabaseEvent> getMessages(String userId) {
    // Limit to last 50 for performance
    return _dbRef
        .child('chats')
        .child('messages')
        .child(userId)
        .orderByChild('timestamp')
        .limitToLast(50)
        .onValue;
  }

  // Get Chat List (for Admin)
  Stream<DatabaseEvent> getChatList() {
    return _dbRef
        .child('chats')
        .child('summaries')
        .orderByChild('lastMessageTime')
        .onValue;
  }
  
  // Mark as read
  Future<void> markAsRead(String userId, bool isAdmin) async {
    Map<String, Object> updateData = {};
    if (isAdmin) {
      updateData['unreadAdmin'] = false;
    } else {
      updateData['unreadUser'] = false;
    }
    
    await _dbRef.child('chats').child('summaries').child(userId).update(updateData);
  }
}
