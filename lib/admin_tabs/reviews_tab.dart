// These import statements are essential. The error means the project can't find them.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewsTab extends StatelessWidget {
  // Added a key to the constructor to satisfy best practices.
  ReviewsTab({super.key});

  final CollectionReference reviews = FirebaseFirestore.instance.collection(
    'reviews',
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: reviews.snapshots(),
      builder: (context, snapshot) {
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
            return ListTile(
              title: Text("Rating: ${review['rating'] ?? 'N/A'}"),
              subtitle: Text(review['comment'] ?? ''),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  await reviews.doc(review.id).delete();
                },
              ),
            );
          },
        );
      },
    );
  }
}
