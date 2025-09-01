import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
// import 'home_screen.dart'; // FIX: Removed this unused import
import 'edit_vendor_profile_page.dart';

class VendorDashboard extends StatelessWidget {
  const VendorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text("Error: No user logged in. Please restart the app."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log Out',
            onPressed: () async {
              await AuthService().signOut();
              if (!context.mounted) return;
              // Navigating to the root route '/' does not require the HomeScreen import.
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vendors')
            .doc(currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text("Could not load your profile data."),
            );
          }

          final vendorData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${vendorData['name'] ?? 'Vendor'}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Here you can manage your public profile and view your activity.',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const Divider(height: 40),

                const Text(
                  'YOUR PUBLIC PROFILE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildProfileInfoRow(
                          Icons.store,
                          'Business Name',
                          vendorData['name'] ?? 'Not set',
                        ),
                        const SizedBox(height: 16),
                        _buildProfileInfoRow(
                          Icons.category,
                          'Service Category',
                          vendorData['category'] ?? 'Not set',
                        ),
                        const SizedBox(height: 16),
                        _buildProfileInfoRow(
                          Icons.description,
                          'Description',
                          (vendorData['description'] ?? 'Not set').length > 50
                              ? '${(vendorData['description'] as String).substring(0, 50)}...'
                              : vendorData['description'] ?? 'Not set',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditVendorProfilePage()),
          );
        },
        label: const Text('Edit Profile'),
        icon: const Icon(Icons.edit),
        backgroundColor: const Color(0xFF2575FC),
      ),
    );
  }

  Widget _buildProfileInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF6A11CB), size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
