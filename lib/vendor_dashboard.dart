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
            return _buildIncompleteProfileView(context);
          }

          final vendorData = snapshot.data!.data() as Map<String, dynamic>;
          final String status = vendorData['status'] ?? 'incomplete';

          switch (status) {
            case 'incomplete':
              return _buildIncompleteProfileView(context);
            case 'pending_approval':
              return _buildDashboardView(context, vendorData, isPending: true);
            case 'approved':
              return _buildDashboardView(context, vendorData, isPending: false);
            default:
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
          const Icon(Icons.edit_note, size: 80, color: Color(0xFF2575FC)),
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

  // --- SHARED WIDGET FOR 'approved' & 'pending_approval' STATUSES ---
  Widget _buildDashboardView(
      BuildContext context, Map<String, dynamic> vendorData,
      {required bool isPending}) {
    final String companyLogo = vendorData['company_logo'] ?? '';
    final String companyName = vendorData['name'] ?? 'Vendor';
    final String location = vendorData['location'] ?? 'Unknown Location';
    final List<dynamic> services = vendorData['services'] ?? [];

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- VENDOR PROFILE HEADER ---
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: companyLogo.isNotEmpty
                    ? NetworkImage(companyLogo) as ImageProvider
                    : null,
                child: companyLogo.isEmpty
                    ? const Icon(Icons.business, size: 50, color: Colors.grey)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                companyName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, size: 18, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    location,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (isPending)
                const Column(
                  children: [
                    Icon(Icons.hourglass_top_rounded, size: 40, color: Colors.amber),
                    SizedBox(height: 8),
                    Text(
                      'Profile Under Review',
                      style: TextStyle(fontSize: 16, color: Colors.amber),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'An admin will check your details shortly.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              if (!isPending)
                const Column(
                  children: [
                    Icon(Icons.check_circle_outline, size: 40, color: Colors.green),
                    SizedBox(height: 8),
                    Text(
                      'Profile Approved',
                      style: TextStyle(fontSize: 16, color: Colors.green),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // --- MANAGE PROFILE & CHAT BUTTONS ---
        _buildMenuItem(
          context: context,
          icon: Icons.edit_outlined,
          title: 'Edit My Profile',
          color: const Color(0xFF6A11CB),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditVendorProfilePage()),
          ),
        ),
        _buildMenuItem(
          context: context,
          icon: Icons.chat_bubble_outline,
          title: 'My Inbox',
          color: const Color(0xFF2575FC),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatListPage()),
          ),
        ),

        const SizedBox(height: 24),
        const Text(
          'My Services',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // --- LIST OF SERVICES ---
        if (services.isEmpty)
          const Center(
            child: Text(
              'No services added yet.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ...services.map((service) {
          return _buildServiceCard(service);
        }).toList(),
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

  Widget _buildServiceCard(Map<String, dynamic> service) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (service['image_url'] != null && service['image_url'].isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                service['image_url'],
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service['title'] ?? 'No Title',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${service['price'] ?? 'N/A'}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6A11CB)),
                ),
                const SizedBox(height: 8),
                Text(
                  service['description'] ?? 'No description provided.',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}