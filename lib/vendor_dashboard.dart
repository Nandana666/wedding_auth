// lib/vendor_dashboard.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'edit_vendor_profile_page.dart';
import 'chat_list_page.dart';

class VendorDashboard extends StatelessWidget {
  const VendorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Not logged in.")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
          final String status = vendorData['status'] ?? 'incomplete';

          // --- CONDITIONAL UI BASED ON VENDOR STATUS ---
          switch (status) {
            case 'incomplete':
              return _buildIncompleteProfileView(context);
            case 'pending_approval':
              return _buildPendingApprovalView(context);
            case 'approved':
              return _buildApprovedDashboardView(context, vendorData);
            default: // Covers 'declined' or any other unexpected status
              return _buildDeclinedView(context);
          }
        },
      ),
    );
  }

  // --- WIDGET FOR 'incomplete' STATUS ---
  Widget _buildIncompleteProfileView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.edit_note, size: 80, color: Colors.blueAccent),
          const SizedBox(height: 20),
          const Text(
            'Complete Your Profile',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Please fill in all your business details to submit your profile for admin review.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Get Started'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF2575FC),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EditVendorProfilePage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- WIDGET FOR 'pending_approval' STATUS ---
  Widget _buildPendingApprovalView(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_top_rounded, size: 80, color: Colors.amber),
            SizedBox(height: 20),
            Text(
              'Your Profile is Under Review',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'An admin will review your details shortly. Thank you for your patience!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET FOR 'approved' STATUS ---
  Widget _buildApprovedDashboardView(
    BuildContext context,
    Map<String, dynamic> vendorData,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'Welcome, ${vendorData['name'] ?? 'Vendor'}!',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Manage your profile and respond to inquiries.',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
        const Divider(height: 40),
        _buildMenuItem(
          context: context,
          icon: Icons.inbox_outlined,
          title: 'My Inbox',
          color: Colors.blue.shade400,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatListPage()),
          ),
        ),
        const SizedBox(height: 10),
        _buildMenuItem(
          context: context,
          icon: Icons.edit_outlined,
          title: 'Edit My Profile',
          color: Colors.green.shade400,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditVendorProfilePage()),
          ),
        ),
      ],
    );
  }

  // --- WIDGET FOR 'declined' STATUS ---
  Widget _buildDeclinedView(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, size: 80, color: Colors.red),
            SizedBox(height: 20),
            Text(
              'Application Declined',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'Unfortunately, your vendor application was not approved at this time. Please contact support for more information.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for consistent menu item styling
  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Color color = const Color(0xFF6A11CB),
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
      ),
    );
  }
}
