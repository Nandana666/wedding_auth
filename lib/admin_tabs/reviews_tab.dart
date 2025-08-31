import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewsTab extends StatelessWidget {
  final CollectionReference reviews = FirebaseFirestore.instance.collection('reviews');

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: reviews.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
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
