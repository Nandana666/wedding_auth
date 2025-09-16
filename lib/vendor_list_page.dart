// lib/vendor_list_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vendor_details_page.dart';

class VendorListPage extends StatelessWidget {
  final String categoryName;
  final Color appBarColor;

  VendorListPage({
    super.key,
    required this.categoryName,
    this.appBarColor = Colors.deepPurple,
  });

  final CollectionReference vendors =
      FirebaseFirestore.instance.collection('vendors');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$categoryName Vendors'),
        backgroundColor: appBarColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: vendors
            .where('categories', arrayContains: categoryName)
            .where('status', isEqualTo: 'approved')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('No approved $categoryName vendors found.'),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final vendor = docs[index];
              final vendorData = vendor.data() as Map<String, dynamic>;
              final String name = vendorData['name'] ?? 'Vendor Name';
              final String location = vendorData['location'] ?? 'N/A';
              final String vendorId = vendor.id;

              // Collect images
              final List<String> imageUrls = [];
              if (vendorData['company_logo'] != null &&
                  vendorData['company_logo'].toString().isNotEmpty) {
                imageUrls.add(vendorData['company_logo']);
              }

              final servicesList = vendorData['services'] as List<dynamic>? ?? [];
              for (var service in servicesList) {
                if (service is Map) {
                  // Handle multiple images per service
                  if (service['image_urls'] != null &&
                      service['image_urls'] is List &&
                      (service['image_urls'] as List).isNotEmpty) {
                    imageUrls.addAll(
                        (service['image_urls'] as List).map((e) => e.toString()));
                  }
                  // (Optional) backward compatibility with old single image field
                  else if (service['image_url'] != null &&
                      service['image_url'].toString().isNotEmpty) {
                    imageUrls.add(service['image_url']);
                  }
                }
              }

              if (imageUrls.isEmpty) {
                imageUrls.add(
                    'https://via.placeholder.com/400x200/CCCCCC/FFFFFF?text=No+Image');
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                elevation: 4,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VendorDetailsPage(
                          vendorId: vendorId,
                          vendorData: vendorData,
                          preSelectedCategory: categoryName,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Swipeable image gallery
                      SizedBox(
                        height: 200,
                        child: PageView.builder(
                          itemCount: imageUrls.length,
                          itemBuilder: (context, i) {
                            return Image.network(
                              imageUrls[i],
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.grey.shade600,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  location,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
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
