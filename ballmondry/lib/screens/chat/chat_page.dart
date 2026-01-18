import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/chat_service.dart';

class ChatPage extends StatefulWidget {
  final String chatId; // This is always the User ID
  final bool isViewerAdmin;
  final String chatTitle; // Name of the other person
  final String currenUserDisplayName; // For updating user name in DB

  const ChatPage({
    super.key,
    required this.chatId,
    required this.isViewerAdmin,
    required this.chatTitle,
    required this.currenUserDisplayName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Mark as read when opening
    _chatService.markAsRead(widget.chatId, widget.isViewerAdmin);
  }

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      String msg = _messageController.text;
      _messageController.clear();
      
      await _chatService.sendMessage(
        widget.chatId,
        msg,
        widget.isViewerAdmin,
        widget.currenUserDisplayName
      );

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatTitle),
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _chatService.getMessages(widget.chatId),
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
                      "Belum ada pesan.\nMulai percakapan!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                DataSnapshot dataSnapshot = snapshot.data!.snapshot;
                Map<dynamic, dynamic> map = dataSnapshot.value as Map<dynamic, dynamic>;
                List<dynamic> list = map.values.toList();
                
                // Sort by timestamp
                list.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    var data = list[index];
                    bool isMe = widget.isViewerAdmin ? (data['isAdmin'] == true) : (data['isAdmin'] == false);
                    
                    return _buildMessageBubble(data['text'], isMe, data['timestamp']);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), offset: const Offset(0, -2), blurRadius: 4)],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: "Tulis pesan...",
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send, color: Colors.deepPurple),
          )
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String message, bool isMe, int time) {
    // Format time can be added here
    return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: isMe ? Colors.deepPurple : Colors.grey[200],
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(0),
              bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(12),
            ),
          ),
          child: Text(
            message,
            style: TextStyle(color: isMe ? Colors.white : Colors.black87),
          ),
        ),
      );
  }
}
