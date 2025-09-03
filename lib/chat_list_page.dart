// lib/chat_list_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to see your messages.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Inbox')),
      body: StreamBuilder<QuerySnapshot>(
        // This is the query that requires the composite index.
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUser.uid)
            .orderBy('lastMessageTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // --- IMPROVEMENT: Handle the error gracefully ---
          if (snapshot.hasError) {
            // This will now catch the "missing index" error and show a helpful message.
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Something went wrong. The required database index may be building. Please try again in a few minutes.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('You have no messages yet.'));
          }

          final chatDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chatData = chatDocs[index].data() as Map<String, dynamic>;
              final List<dynamic> participants = chatData['participants'] ?? [];

              final otherUserId = participants.firstWhere(
                (id) => id != currentUser.uid,
                orElse: () => null,
              );

              if (otherUserId == null) return const SizedBox.shrink();

              final String otherUserName =
                  chatData['participantNames']?[otherUserId] ?? 'User';
              final String lastMessage = chatData['lastMessage'] ?? '...';

              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    otherUserName.isNotEmpty
                        ? otherUserName[0].toUpperCase()
                        : 'U',
                  ),
                ),
                title: Text(
                  otherUserName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
