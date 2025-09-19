// lib/user_dashboard.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_user_profile_page.dart';
import 'vendor_details_page.dart';
import 'auth_service.dart';
import 'chat_list_page.dart';

class UserDashboard extends StatelessWidget {
  const UserDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // This is a fallback, AuthGate should prevent this screen from being reached
      return const Scaffold(body: Center(child: Text("Not logged in.")));
    }

    final userDocStream = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
          final List<dynamic> shortlistedVendorIds =
              userData['shortlistedVendors'] ?? [];

          return CustomScrollView(
            slivers: [
              _buildProfileHeader(context, userData),

              SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),

                  // --- Shortlisted Vendors Section ---
                  _buildSectionHeader('My Shortlisted Vendors'),
                  const SizedBox(height: 10),
                  shortlistedVendorIds.isEmpty
                      ? _buildEmptyShortlistCard()
                      : _buildShortlistedVendorsList(shortlistedVendorIds),

                  const SizedBox(height: 20),

                  // --- Booking History Section ---
                  _buildSectionHeader('My Bookings / History'),
                  const SizedBox(height: 10),
                  _buildBookingHistory(currentUser.uid),

                  const SizedBox(height: 20),

                  // --- Account Section ---
                  _buildSectionHeader('Account'),
                  const SizedBox(height: 10),

                  // Inbox
                  _buildMenuItem(
                    context: context,
                    icon: Icons.inbox_outlined,
                    title: 'My Inbox',
                    color: Colors.blue.shade400,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatListPage()),
                      );
                    },
                  ),

                  // Logout
                  _buildMenuItem(
                    context: context,
                    icon: Icons.logout,
                    title: 'Log Out',
                    color: Colors.red.shade400,
                    onTap: () async {
                      await AuthService().signOut();
                      if (!context.mounted) return;
                      // Navigate back to the root, which should be handled by AuthGate
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (route) => false,
                      );
                    },
                  ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  // ------------------ Helper Widgets ------------------

  Widget _buildProfileHeader(
      BuildContext context, Map<String, dynamic> userData) {
    final String name = userData['name'] ?? 'User';
    final String email = userData['email'] ?? 'No email';
    return SliverAppBar(
      expandedHeight: 220.0,
      pinned: true,
      backgroundColor: const Color(0xFFF472B6),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF472B6), Color(0xFF60A5FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 32,
                            color: Color(0xFF60A5FA),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            tooltip: 'Edit Profile',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditUserProfilePage(userData: userData),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildEmptyShortlistCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(24.0),
        child: Text(
          'Tap the ❤️ on a vendor\'s page to save them here!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildShortlistedVendorsList(List<dynamic> vendorIds) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vendorIds.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final vendorId = vendorIds[index];
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('vendors')
              .doc(vendorId)
              .get(),
          builder: (context, vendorSnapshot) {
            if (!vendorSnapshot.hasData || !vendorSnapshot.data!.exists) {
              return const SizedBox.shrink();
            }
            final vendorData =
                vendorSnapshot.data!.data() as Map<String, dynamic>;
            return _buildMenuItem(
              context: context,
              icon: Icons.storefront,
              title: vendorData['name'] ?? 'Vendor',
              subtitle: vendorData['category'] ?? 'Category',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VendorDetailsPage(
                    vendorId: vendorId,
                    vendorData: vendorData,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBookingHistory(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('bookings')
          .orderBy('eventDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                "You haven't booked any vendors yet.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final bookings = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: ListTile(
                title: Text(
                  booking['vendorName'] ?? 'Vendor',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Category: ${booking['vendorCategory'] ?? 'N/A'}"),
                    Text("Booking Date: ${_formatDate(booking['bookingDate'])}"),
                    Text("Event Date: ${_formatDate(booking['eventDate'])}"),
                    Text("Advance Paid: ₹${booking['advancePayment'] ?? 0}"),
                    Text(
                        "Payment Status: ${booking['paymentStatus'] ?? 'N/A'}"),
                    Text("Event Status: ${booking['eventStatus'] ?? 'N/A'}"),
                  ],
                ),
                trailing: const Icon(Icons.event, color: Colors.blue),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "N/A";
    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color color = const Color(0xFFF472B6),
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      shadowColor: Colors.black.withAlpha(13),
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
        title:
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: onTap != null
            ? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)
            : null,
      ),
    );
  }
}