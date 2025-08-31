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
  double minPrice = 0;
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Kerala Wedding"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserDashboard()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
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
      body: Stack(
        children: [
          // Background Image
          SizedBox.expand(
            child: Image.asset(
              'assets/admin_bg.jpg', // Replace with your image path
              fit: BoxFit.cover,
            ),
          ),
          // FIX: Replaced deprecated withOpacity
          // Optional: Add a semi-transparent overlay for readability
          Container(
            color: const Color.fromARGB(25, 0, 0, 0), // 10% opacity black
          ),
          // Main Content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchAndFilters(),
                _buildCategorySection(),
                _buildVendorSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Search + Filters Section
  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search vendors...',
              filled: true,
              fillColor: Colors.white,
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
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: maxPrice,
                  min: 0,
                  max: 100000,
                  divisions: 20,
                  label: "Max ₹$maxPrice",
                  onChanged: (value) {
                    setState(() {
                      maxPrice = value;
                    });
                  },
                ),
              ),
              DropdownButton<double>(
                value: minRating,
                items: [0, 1, 2, 3, 4, 5]
                    .map(
                      (e) => DropdownMenuItem<double>(
                        value: e.toDouble(),
                        child: Text("$e+⭐"),
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
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _categoryCard(category['title'], category['icon']);
        },
      ),
    );
  }

  /// Vendor Grid Section
  Widget _buildVendorSection() {
    return StreamBuilder<QuerySnapshot>(
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
          final price = double.tryParse(data['price'].toString()) ?? 0;
          final rating = double.tryParse(data['rating'].toString()) ?? 0;

          return name.contains(searchQuery) &&
              price >= minPrice &&
              price <= maxPrice &&
              rating >= minRating;
        }).toList();

        if (vendors.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(child: Text('No vendors match your filters')),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: vendors.length,
          itemBuilder: (context, index) {
            final vendor = vendors[index];
            return _vendorCard(vendor);
          },
        );
      },
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
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.pink, size: 30),
            const SizedBox(height: 6),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  /// Vendor Card
  Widget _vendorCard(DocumentSnapshot vendor) {
    final data = vendor.data() as Map<String, dynamic>;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VendorDetailsPage(vendorData: data),
          ),
        );
      },
      child: Card(
        elevation: 3,
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
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "${data['rating'] ?? '0.0'} ⭐",
                    style: const TextStyle(fontSize: 14),
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
