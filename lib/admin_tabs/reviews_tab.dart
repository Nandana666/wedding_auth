// lib/admin_tabs/reviews_tab.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewsTab extends StatelessWidget {
  ReviewsTab({super.key});

  final CollectionReference reviews = FirebaseFirestore.instance.collection(
    'reviews',
  );

  Widget _buildRating(dynamic ratingValue) {
    if (ratingValue is num) {
      return Row(
        children: List.generate(
          ratingValue.toInt(),
          (index) => const Icon(Icons.star, color: Colors.amber, size: 18),
        ).toList(),
      );
    }
    return Text("Rating: $ratingValue");
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: reviews.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No reviews found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final review = docs[index];
            final data = review.data() as Map<String, dynamic>?;

            if (data == null) {
              return const Card(
                child: ListTile(title: Text('Invalid review data')),
              );
            }

            final rating = data['rating'] ?? 'N/A';
            final comment = data['comment'] ?? 'No comment provided.';
            final userName = data['userName'] ?? 'Unknown User';
            final vendorName = data['vendorName'] ?? 'Unknown Vendor';

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                key: ValueKey(review.id),
                title: _buildRating(rating),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "By: $userName for $vendorName",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
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
                        content: const Text(
                          'Are you sure you want to permanently delete this review?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await reviews.doc(review.id).delete();
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
    );
  }
}
