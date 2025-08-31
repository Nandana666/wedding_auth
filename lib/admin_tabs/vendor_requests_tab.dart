import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vendor_request_detail_page.dart';

class VendorRequestsTab extends StatelessWidget {
  // FIX: Removed 'const' from the constructor because 'vendorsRef' is not constant.
  VendorRequestsTab({super.key});

  final CollectionReference vendorsRef =
      FirebaseFirestore.instance.collection('vendor_requests');

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: vendorsRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No vendor requests found."));
        }

        return ListView(
          children: snapshot.data!.docs.map((doc) {
            final vendor = doc.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.all(10),
              child: ListTile(
                title: Text(vendor['name'] ?? "No Name"),
                subtitle: Text("Service: ${vendor['serviceType'] ?? '-'}"),
                trailing: ElevatedButton(
                  child: const Text("View Details"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VendorRequestDetailPage(
                          vendorData: vendor,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}