import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'vendor_makeup_page.dart';
import 'vendor_food_page.dart';
import 'vendor_decoration_page.dart';
import 'vendor_photography_page.dart';
import 'vendor_venues_page.dart';
import 'vendor_details_page.dart';
import 'vendor_packages_page.dart';
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

  final List<Map<String, dynamic>> categories = [
    {'title': 'Venues', 'icon': Icons.location_city},
    {'title': 'Makeup', 'icon': Icons.brush},
    {'title': 'Catering', 'icon': Icons.restaurant},
    {'title': 'Photography', 'icon': Icons.camera_alt},
    {'title': 'Decor', 'icon': Icons.event},
    {'title': 'Packages', 'icon': Icons.card_giftcard},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kerala Wedding Planner"),
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
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
          ],
        ),
      ),
    );
  }

  /// Search + Filters Section
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

  /// Categories Section
  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Categories',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _categoryCard(category['title'], category['icon']);
            },
          ),
        ),
      ],
    );
  }

  /// Vendor Grid Section
  Widget _buildVendorSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('vendors')
            .where('status', isEqualTo: 'approved')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No vendors available'));
          }

          final vendors = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final category = (data['category'] ?? '').toString().toLowerCase();
            final price = double.tryParse(data['price'].toString()) ?? 0;
            final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;

            return (name.contains(searchQuery) ||
                    category.contains(searchQuery)) &&
                (price == 0 || price <= maxPrice) &&
                rating >= minRating;
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
              crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 4,
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
    );
  }

  /// Category Card Navigation
  Widget _categoryCard(String title, IconData icon) {
    return GestureDetector(
      onTap: () {
        Widget page;
        switch (title) {
          case 'Venues':
            page = VendorVenuesPage();
            break;
          case 'Makeup':
            page = VendorMakeupPage();
            break;
          case 'Catering':
            page = VendorFoodPage();
            break;
          case 'Photography':
            page = VendorPhotographyPage();
            break;
          case 'Decor':
            page = VendorDecorationPage();
            break;
          case 'Packages':
            page = VendorPackagesPage();
            break;
          default:
            page = VendorVenuesPage();
        }
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              // FIX: Replaced deprecated withOpacity
              color: Colors.black.withAlpha(13), // 5% opacity
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.pink, size: 30),
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

  /// Vendor Card
  Widget _vendorCard(DocumentSnapshot vendor) {
    final data = vendor.data() as Map<String, dynamic>;
    final vendorId = vendor.id;

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
        // FIX: Replaced deprecated withOpacity
        shadowColor: Colors.black.withAlpha(26), // 10% opacity
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                data['image'] ?? 'https://via.placeholder.com/150',
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
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
