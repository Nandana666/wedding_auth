// lib/admin_tabs/reviews_tab.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewsTab extends StatelessWidget {
  const ReviewsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final reviewsCollection = FirebaseFirestore.instance.collection('reviews');

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Reviews'),
        backgroundColor: const Color(0xFFF472B6),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: reviewsCollection.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error fetching reviews: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No reviews found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final rating = (data['rating'] ?? 0).toDouble();
              final comment = data['comment'] ?? 'No comment';
              final userName = data['userName'] ?? 'Unknown User';
              final vendorName = data['vendorName'] ?? 'Unknown Vendor';
              final Timestamp? createdAt = data['createdAt'] as Timestamp?;
              final dateString = createdAt != null
                  ? "${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}"
                  : "Unknown date";

              // Build stars
              List<Widget> stars = [];
              int fullStars = rating.floor();
              bool halfStar = (rating - fullStars) >= 0.5;
              for (int i = 0; i < fullStars; i++) {
                stars.add(const Icon(Icons.star, color: Colors.amber, size: 18));
              }
              if (halfStar) {
                stars.add(const Icon(Icons.star_half, color: Colors.amber, size: 18));
              }
              for (int i = stars.length; i < 5; i++) {
                stars.add(const Icon(Icons.star_border, color: Colors.amber, size: 18));
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  title: Text(vendorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Row(children: stars),
                      const SizedBox(height: 6),
                      Text(comment),
                      const SizedBox(height: 6),
                      Text(
                        "By $userName on $dateString",
                        style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red.shade400),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Review'),
                          content: const Text('Are you sure you want to delete this review?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await reviewsCollection.doc(docs[index].id).delete();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Review deleted')),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
