import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VendorFoodPage extends StatelessWidget {
  VendorFoodPage({super.key});

  final CollectionReference vendors =
      FirebaseFirestore.instance.collection('vendors');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Vendors'),
        backgroundColor: Colors.orange, // Theme color for food vendors
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: vendors
            .where('category', isEqualTo: 'food')
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

              final images = List<String>.from(vendorData['images'] ?? []);
              final services = List<String>.from(vendorData['services'] ?? []);

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
                                vendorData['name'] ?? 'Vendor Name',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 20),
                                  Text(
                                    '${vendorData['rating'] ?? 'N/A'}',
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
                              'Cuisine: ${services.join(', ')}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          const SizedBox(height: 6),

                          // Price
                          if (vendorData['priceRange'] != null)
                            Text(
                              'Price per plate: ${vendorData['priceRange']}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          const SizedBox(height: 6),

                          // Location
                          if (vendorData['location'] != null)
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: Colors.orange, size: 18),
                                const SizedBox(width: 6),
                                Text(vendorData['location']),
                              ],
                            ),
                          const SizedBox(height: 6),

                          // Contact
                          if (vendorData['contact'] != null)
                            Row(
                              children: [
                                const Icon(Icons.phone,
                                    color: Colors.orange, size: 18),
                                const SizedBox(width: 6),
                                Text(vendorData['contact']),
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
                                    content: Text(
                                        'Booking ${vendorData['name']}...'),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
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
