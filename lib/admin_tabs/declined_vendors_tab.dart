import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeclinedVendorsTab extends StatelessWidget {
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
          return const Center(
            child: Text(
              'No declined vendors found.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                'Declined Vendors',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: declinedVendors.length,
                itemBuilder: (context, index) {
                  final vendor = declinedVendors[index];
                  final name = vendor['name'] ?? 'No Name';

                  return Card(
                    elevation: 2,
                    color: Colors.red.shade50,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red.shade100,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'V',
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(vendor['email'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                        tooltip: 'Delete Permanently',
                        onPressed: () async {
                          // It's good practice to capture context-dependent variables before async gaps.
                          final scaffoldMessenger = ScaffoldMessenger.of(
                            context,
                          );

                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete Declined Vendor'),
                              content: const Text(
                                'This action is permanent. Are you sure you want to delete this vendor?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );

                          // Check if the widget is still mounted after the dialog
                          if (confirm != true || !context.mounted) return;

                          // The second async gap
                          await vendors.doc(vendor.id).delete();

                          // THE FIX: Check if the widget is *still* mounted after the delete operation
                          if (context.mounted) {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text('Declined vendor deleted'),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
