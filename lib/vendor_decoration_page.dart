import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VendorDecorationPage extends StatelessWidget {
  VendorDecorationPage({super.key});

  final CollectionReference vendors =
      FirebaseFirestore.instance.collection('vendors');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Decoration Vendors'),
        backgroundColor: Colors.green, // Different color for decoration
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: vendors
            .where('category', isEqualTo: 'decor') // lowercase for consistency
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
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final vendor = docs[index];
              final vendorData = vendor.data() as Map<String, dynamic>;

              // ✅ Safe conversions
              final images = (vendorData['images'] as List?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  [];
              final services = (vendorData['services'] as List?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  [];
              final name = vendorData['name']?.toString() ?? 'Vendor Name';
              final rating = vendorData['rating']?.toString() ?? 'N/A';
              final priceRange = vendorData['priceRange']?.toString() ?? '';
              final contact = vendorData['contact']?.toString() ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image carousel
                    if (images.isNotEmpty)
                      SizedBox(
                        height: 200,
                        child: PageView.builder(
                          itemCount: images.length,
                          itemBuilder: (context, i) {
                            return ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                              child: Image.network(
                                images[i],
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image, size: 50),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                        ),
                        child: const Center(
                          child: Icon(Icons.image,
                              size: 50, color: Colors.white),
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name & Rating
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 20),
                                  Text(
                                    rating,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Services
                          if (services.isNotEmpty)
                            Text(
                              'Services: ${services.join(', ')}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          const SizedBox(height: 6),

                          // Price
                          if (priceRange.isNotEmpty)
                            Text(
                              'Price: $priceRange',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          const SizedBox(height: 6),

                          // Contact
                          if (contact.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.phone,
                                    color: Colors.green, size: 18),
                                const SizedBox(width: 6),
                                Text(contact),
                              ],
                            ),
                          const SizedBox(height: 10),

                          // Book button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Booking $name...'),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Book Now'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
