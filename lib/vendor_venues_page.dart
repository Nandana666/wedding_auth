import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vendor_details_page.dart';

class VendorVenuesPage extends StatelessWidget {
  VendorVenuesPage({super.key});

  final CollectionReference vendors = FirebaseFirestore.instance.collection(
    'vendors',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Venue Vendors")),
      body: StreamBuilder<QuerySnapshot>(
        stream: vendors
            // Important: Firestore queries are case-sensitive. Use a consistent case.
            .where('category', isEqualTo: 'venues')
            .where('status', isEqualTo: 'approved')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No venue vendors found'));
          }

          final vendorDocs = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: vendorDocs.length,
            itemBuilder: (context, index) {
              final vendor = vendorDocs[index];
              // FIX: Get both the vendor's data and its unique ID.
              final vendorData = vendor.data() as Map<String, dynamic>;
              final vendorId = vendor.id;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // FIX: Pass both required parameters to VendorDetailsPage.
                      builder: (_) => VendorDetailsPage(
                        vendorId: vendorId,
                        vendorData: vendorData,
                      ),
                    ),
                  );
                },
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.network(
                          vendorData['image'] ??
                              'https://via.placeholder.com/150',
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          vendorData['name'] ?? 'Vendor Name',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                vendorData['location'] ?? 'Location',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
