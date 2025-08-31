import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VendorDecorationPage extends StatelessWidget {
  VendorDecorationPage({super.key});

  final CollectionReference vendors =
      FirebaseFirestore.instance.collection('vendors');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Decoration Vendors')),
      body: StreamBuilder<QuerySnapshot>(
        stream: vendors
            .where('category', isEqualTo: 'decoration')
            .where('status', isEqualTo: 'approved')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No vendors available.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final vendor = docs[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.event, color: Colors.white),
                  ),
                  title: Text(vendor['name']),
                  subtitle: Text(vendor['description'] ?? ''),
                  trailing: Text('${vendor['rating'] ?? 'N/A'} ⭐'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
