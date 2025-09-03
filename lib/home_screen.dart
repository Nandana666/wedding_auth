// lib/home_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- UPDATED IMPORTS ---
// Removed individual vendor pages and added the single reusable list page.
import 'vendor_list_page.dart';
import 'vendor_details_page.dart';
import 'user_dashboard.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String searchQuery = '';
  double maxPrice = 100000;
  double minRating = 0;

  // Added colors to easily customize each category page
  final List<Map<String, dynamic>> categories = [
    {'title': 'Venues', 'icon': Icons.location_city, 'color': Colors.brown},
    {'title': 'Makeup', 'icon': Icons.brush, 'color': Colors.pink},
    {'title': 'Catering', 'icon': Icons.restaurant, 'color': Colors.orange},
    {
      'title': 'Photography',
      'icon': Icons.camera_alt,
      'color': Colors.blueGrey,
    },
    {'title': 'Decor', 'icon': Icons.event, 'color': Colors.green},
    {'title': 'Packages', 'icon': Icons.card_giftcard, 'color': Colors.purple},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Wedding Planner"),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'My Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserDashboard()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log Out',
            onPressed: () async {
              await _auth.signOut();
              if (context.mounted) {
                // Use pushAndRemoveUntil for a clean navigation stack after logout
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchAndFilters(),
            _buildCategorySection(),
            _buildVendorSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find Your Perfect Vendor',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search by name or category...',
              filled: true,
              fillColor: Colors.grey.shade200,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase();
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Max Price: ₹${maxPrice.toInt()}",
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    Slider(
                      value: maxPrice,
                      min: 0,
                      max: 100000,
                      divisions: 20,
                      label: "₹${maxPrice.toInt()}",
                      onChanged: (value) {
                        setState(() {
                          maxPrice = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<double>(
                value: minRating,
                underline: const SizedBox(),
                items: [0, 1, 2, 3, 4, 5]
                    .map(
                      (e) => DropdownMenuItem<double>(
                        value: e.toDouble(),
                        child: Text("$e+ ⭐"),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    minRating = value ?? 0;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            'Categories',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _categoryCard(
                category['title'],
                category['icon'],
                category['color'],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVendorSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Popular Vendors',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('vendors')
                .where('status', isEqualTo: 'approved')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No approved vendors available yet.'),
                );
              }

              // Client-side filtering
              final vendors = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? '').toString().toLowerCase();
                final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
                // Note: Price filtering would need adjustment based on your data structure
                return name.contains(searchQuery) && rating >= minRating;
              }).toList();

              if (vendors.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(child: Text('No vendors match your filters')),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width < 600
                      ? 2
                      : 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: vendors.length,
                itemBuilder: (context, index) {
                  final vendor = vendors[index];
                  return _vendorCard(vendor);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _categoryCard(String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        // --- REFACTORED NAVIGATION ---
        // No more switch statement. Navigate to the single reusable page.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                VendorListPage(categoryName: title, appBarColor: color),
          ),
        );
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vendorCard(DocumentSnapshot vendor) {
    final data = vendor.data() as Map<String, dynamic>;
    final vendorId = vendor.id;

    // Get an image URL, falling back from company logo to the first service image.
    String imageUrl = data['company_logo'] ?? '';
    if (imageUrl.isEmpty) {
      final services = data['services'] as List<dynamic>?;
      if (services != null && services.isNotEmpty) {
        final firstService = services.first as Map<String, dynamic>?;
        if (firstService != null && firstService['image_url'] != null) {
          imageUrl = firstService['image_url'];
        }
      }
    }
    if (imageUrl.isEmpty) {
      imageUrl = 'https://via.placeholder.com/150';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                VendorDetailsPage(vendorId: vendorId, vendorData: data),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withAlpha(26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey.shade400,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                data['name'] ?? 'Vendor Name',
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
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    (data['rating'] as num?)?.toStringAsFixed(1) ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    data['location'] ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
