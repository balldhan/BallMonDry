import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/chat_service.dart';
import 'chat_page.dart';

class AdminChatListPage extends StatefulWidget {
  const AdminChatListPage({super.key});

  @override
  State<AdminChatListPage> createState() => _AdminChatListPageState();
}

class _AdminChatListPageState extends State<AdminChatListPage> {
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat Pelanggan"),
      ),
      body: StreamBuilder(
        stream: _chatService.getChatList(),
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Text(
                "Belum ada pesan dari pelanggan.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          DataSnapshot dataSnapshot = snapshot.data!.snapshot;
          Map<dynamic, dynamic> map = dataSnapshot.value as Map<dynamic, dynamic>;
          List<dynamic> list = map.values.toList();

          // Sort descending by last message time
          list.sort((a, b) => (b['lastMessageTime'] ?? 0).compareTo(a['lastMessageTime'] ?? 0));

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              var data = list[index];
              String userId = data['userId'].toString(); // Ensure string
              String username = data['username'] ?? 'User #$userId';
              String lastMessage = data['lastMessage'] ?? '';
              bool isUnread = data['unreadAdmin'] == true;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isUnread ? Colors.red : Colors.grey.shade300,
                  child: Icon(Icons.person, color: isUnread ? Colors.white : Colors.grey.shade700),
                ),
                title: Text(
                  username,
                  style: isUnread ? const TextStyle(fontWeight: FontWeight.bold) : null,
                ),
                subtitle: Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: isUnread ? const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87) : null,
                ),
                trailing: isUnread ? const Icon(Icons.circle, color: Colors.red, size: 12) : null,
                onTap: () {
                  // Navigate to chat
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        chatId: userId,
                        isViewerAdmin: true,
                        chatTitle: username,
                        currenUserDisplayName: 'Admin',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
