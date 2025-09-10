import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewsTab extends StatelessWidget {
  ReviewsTab({super.key});

  final CollectionReference reviews =
      FirebaseFirestore.instance.collection('reviews');

  Widget _buildRating(dynamic ratingValue) {
    if (ratingValue is num) {
      return Row(
        children: List.generate(
          ratingValue.toInt(),
          (index) => const Icon(Icons.star, color: Colors.amber, size: 18),
        ),
      );
    }
    return Text("Rating: $ratingValue");
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: reviews.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No reviews found.'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final review = docs[index];
            final data = review.data() as Map<String, dynamic>?;

            if (data == null) {
              return const ListTile(
                title: Text('Invalid review data'),
              );
            }

            final rating = data['rating'] ?? 'N/A';
            final comment = data['comment'] ?? '';

            return ListTile(
              key: ValueKey(review.id),
              title: _buildRating(rating),
              subtitle: Text(comment),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Review'),
                      content: const Text(
                          'Are you sure you want to delete this review?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel')),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await reviews.doc(review.id).delete();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Review deleted')),
                    );
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}