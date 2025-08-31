import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeclinedVendorsTab extends StatelessWidget {
  // FIX 1: Removed 'const' because 'vendors' is not a constant value.
  DeclinedVendorsTab({super.key});

  final CollectionReference vendors = FirebaseFirestore.instance.collection(
    'vendors',
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: vendors.where('status', isEqualTo: 'declined').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final declinedVendors = snapshot.data!.docs;
        if (declinedVendors.isEmpty) {
          return const Center(child: Text('No declined vendors'));
        }

        return ListView.builder(
          itemCount: declinedVendors.length,
          itemBuilder: (context, index) {
            final vendor = declinedVendors[index];
            return ListTile(
              title: Text(vendor['name'] ?? 'No Name'),
              subtitle: Text(vendor['email'] ?? ''),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete Declined Vendor'),
                      content: const Text(
                        'Are you sure you want to delete this vendor?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    // This is an async gap
                    await vendors.doc(vendor.id).delete();

                    // FIX 2: Add a 'mounted' check on the context before using it.
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Declined vendor deleted')),
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
