// lib/chat_list_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart'; // We will create this next

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(title: const Text('My Inbox')),
      body: StreamBuilder<QuerySnapshot>(
        // Query the 'chats' collection for conversations involving the current user
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('You have no messages yet.'));
          }

          final chatDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chatData = chatDocs[index].data() as Map<String, dynamic>;
              final List<dynamic> participants = chatData['participants'];
              
              // Find the other person in the chat
              final otherUserId = participants.firstWhere((id) => id != currentUser.uid);
              final String otherUserName = chatData['participantNames'][otherUserId] ?? 'User';
              final String lastMessage = chatData['lastMessage'] ?? '...';
              
              return ListTile(
                leading: CircleAvatar(child: Text(otherUserName[0])),
                title: Text(otherUserName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        chatId: chatDocs[index].id,
                        recipientId: otherUserId,
                        recipientName: otherUserName,
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