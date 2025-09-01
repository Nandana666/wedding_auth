// lib/user_dashboard.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_user_profile_page.dart';
import 'vendor_details_page.dart';
import 'auth_service.dart';

class UserDashboard extends StatelessWidget {
  const UserDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Not logged in.")));
    }

    final userDocStream = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF472B6), Color(0xFF60A5FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: userDocStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Could not load your profile."));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> shortlistedVendorIds = userData['shortlistedVendors'] ?? [];

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- Profile Details Card ---
              _buildProfileCard(context, userData),
              const SizedBox(height: 24),

              // --- History Section ---
              const Text(
                'My History',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildUserHistoryList(userData['uid'] ?? currentUser.uid),
              const SizedBox(height: 24),

              // --- Shortlisted Vendors Section ---
              const Text(
                'My Shortlisted Vendors',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              shortlistedVendorIds.isEmpty
                  ? const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'You haven\'t shortlisted any vendors yet. Tap the ❤️ on a vendor\'s page to save them here!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : _buildShortlistedVendorsList(shortlistedVendorIds),
            ],
          );
        },
      ),
    );
  }

  // --- Profile Card ---
  Widget _buildProfileCard(BuildContext context, Map<String, dynamic> userData) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF60A5FA)),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditUserProfilePage(userData: userData),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.person_outline, 'Name', userData['name'] ?? 'Not set'),
            _buildDetailRow(Icons.email_outlined, 'Email', userData['email'] ?? 'Not set'),
            _buildDetailRow(Icons.location_city_outlined, 'Location', userData['location'] ?? 'Not set'),
          ],
        ),
      ),
    );
  }

  // --- Single Detail Row ---
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 16),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
          Expanded(child: Text(value, style: TextStyle(color: Colors.grey.shade800, fontSize: 16))),
        ],
      ),
    );
  }

  // --- User History List ---
  Widget _buildUserHistoryList(String userId) {
    final historyStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('history')
        .orderBy('timestamp', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: historyStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'You have no history yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final historyDocs = snapshot.data!.docs;

        return Column(
          children: historyDocs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final vendorName = data['vendorName'] ?? 'Vendor';
            final vendorCategory = data['vendorCategory'] ?? '';
            final timestamp = data['timestamp'] != null
                ? (data['timestamp'] as Timestamp).toDate()
                : null;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.history, color: Colors.blue),
                title: Text(vendorName),
                subtitle: Text(vendorCategory +
                    (timestamp != null ? ' • ${timestamp.toLocal()}' : '')),
                onTap: () {
                  if (data['vendorId'] != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VendorDetailsPage(
                          vendorId: data['vendorId'],
                          vendorData: data,
                        ),
                      ),
                    );
                  }
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // --- Shortlisted Vendors List ---
  Widget _buildShortlistedVendorsList(List<dynamic> vendorIds) {
    return Column(
      children: vendorIds.map((vendorId) {
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('vendors').doc(vendorId).get(),
          builder: (context, vendorSnapshot) {
            if (!vendorSnapshot.hasData || !vendorSnapshot.data!.exists) {
              return const SizedBox.shrink();
            }
            final vendorData = vendorSnapshot.data!.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                    vendorData['image'] ?? 'https://via.placeholder.com/150',
                  ),
                ),
                title: Text(vendorData['name'] ?? 'Vendor'),
                subtitle: Text(vendorData['category'] ?? 'Category'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VendorDetailsPage(vendorId: vendorId, vendorData: vendorData),
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
