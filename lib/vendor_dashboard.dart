// lib/vendor_dashboard.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'auth_service.dart';
import 'edit_vendor_profile_page.dart';
import 'chat_list_page.dart';
import 'booking_details_page.dart'; // Ensure this uses the updated list constructor

// --- MAIN VENDOR DASHBOARD WIDGET ---
class VendorDashboard extends StatefulWidget {
  const VendorDashboard({super.key});

  @override
  State<VendorDashboard> createState() => _VendorDashboardState();
}

class _VendorDashboardState extends State<VendorDashboard> {
  Map<String, dynamic> vendorData = {};

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

          vendorData = snapshot.data!.data() as Map<String, dynamic>;
          final String status = vendorData['status'] ?? 'incomplete';

          switch (status) {
            case 'incomplete':
              return _buildIncompleteProfileView(context);
            case 'pending_approval':
              return _buildDashboardView(context, isPending: true);
            case 'approved':
              return _buildDashboardView(context, isPending: false);
            default:
              return _buildDeclinedView(context);
          }
        },
      ),
    );
  }

  Widget _buildDashboardView(BuildContext context, {required bool isPending}) {
    final String companyLogo = vendorData['company_logo'] ?? '';
    final String companyName = vendorData['name'] ?? 'Vendor';
    final String location = vendorData['location'] ?? 'Unknown Location';
    final List<dynamic> services = vendorData['services'] ?? [];
    final vendorId = FirebaseAuth.instance.currentUser!.uid;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- Profile Header ---
        _buildProfileHeader(companyLogo, companyName, location, isPending),

        const SizedBox(height: 24),

        // --- Core Menu Items ---
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

        // --- Client Bookings Option ---
        _buildMenuItem(
          context: context,
          icon: Icons.event_note_outlined,
          title: 'Client Bookings',
          color: Colors.green.shade600,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ClientBookingsPage(vendorId: vendorId, vendorData: vendorData),
            ),
          ),
        ),

        _buildMenuItem(
          context: context,
          icon: Icons.reviews,
          title: 'Reviews',
          color: const Color.fromARGB(255, 205, 220, 71),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExpandableVendorReviews(vendorId: vendorId),
            ),
          ),
        ),

        const SizedBox(height: 24),
        const Text(
          'My Services',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        if (services.isEmpty)
          const Center(
            child: Text(
              'No services added yet.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ...services.map((service) {
          return _buildServiceCard(service as Map<String, dynamic>);
        }),
      ],
    );
  }

  // Helper function extracted from the original build method for clarity
  Widget _buildProfileHeader(
      String logo, String name, String location, bool isPending) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
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
            backgroundImage:
                logo.isNotEmpty ? NetworkImage(logo) as ImageProvider : null,
            child: logo.isEmpty
                ? const Icon(Icons.business, size: 50, color: Colors.grey)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
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
                Icon(Icons.hourglass_top_rounded,
                    size: 40, color: Colors.amber),
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
                Icon(Icons.check_circle_outline,
                    size: 40, color: Colors.green),
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
    );
  }

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
        title:
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final List<dynamic> imageUrls = service['image_urls'] ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imageUrls.isNotEmpty)
            SizedBox(
              height: 200,
              child: PageView.builder(
                itemCount: imageUrls.length,
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.network(
                      imageUrls[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                              size: 50,
                            ),
                          ),
                        );
                      },
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${service['price'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6A11CB),
                  ),
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

// ----------------------------------------------------------------------
// --- DEDICATED PAGE FOR GROUPED CLIENT BOOKINGS ---
// ----------------------------------------------------------------------

class ClientBookingsPage extends StatelessWidget {
  final String vendorId;
  final Map<String, dynamic> vendorData;

  const ClientBookingsPage(
      {super.key, required this.vendorId, required this.vendorData});

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "N/A";
    final date = timestamp.toDate();
    return DateFormat('d MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booked Clients'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vendors')
            .doc(vendorId)
            .collection('bookings')
            .orderBy('bookingDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load client data.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  "You have no client bookings yet.",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final bookings = snapshot.data!.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

          // Group bookings by userId (or fallback to userName)
          final Map<String, List<Map<String, dynamic>>> groupedBookings = {};
          for (var booking in bookings) {
            final String key =
                booking['userId'] ?? booking['userName'] ?? 'Unknown Client';
            groupedBookings.putIfAbsent(key, () => []);
            groupedBookings[key]!.add(booking);
          }

          groupedBookings.forEach((key, list) {
            list.sort((a, b) =>
                (b['bookingDate'] as Timestamp)
                    .compareTo(a['bookingDate'] as Timestamp));
          });

          final List<String> clientKeys = groupedBookings.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: clientKeys.length,
            itemBuilder: (context, index) {
              final clientKey = clientKeys[index];
              final clientBookings = groupedBookings[clientKey]!;
              final clientName =
                  clientBookings.first['userName'] ?? 'Unknown Client';
              final lastBookingDate =
                  clientBookings.first['bookingDate'] as Timestamp?;

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingDetailsPage(
                        clientBookings: clientBookings,
                        vendorData: vendorData,
                      ),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF6A11CB).withAlpha(40),
                      child: Text(
                        clientName.isNotEmpty
                            ? clientName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6A11CB),
                        ),
                      ),
                    ),
                    title: Text(
                      clientName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Total: ${clientBookings.length} booking(s). Last booked: ${_formatDate(lastBookingDate)}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.grey),
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

// ----------------------------------------------------------------------
// --- VENDOR REVIEWS PAGE ---
// ----------------------------------------------------------------------

class ExpandableVendorReviews extends StatelessWidget {
  final String vendorId;
  const ExpandableVendorReviews({super.key, required this.vendorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Reviews'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('vendorId', isEqualTo: vendorId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
                child: Text('Error loading reviews. Please try again.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No reviews yet.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final reviews = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review =
                  reviews[index].data() as Map<String, dynamic>? ?? {};
              final String reviewerName = review['userName'] ?? 'Anonymous';
              final int rating = (review['rating'] ?? 0).toInt();
              final String comment = review['comment'] ?? '';
              final Timestamp? createdAt = review['createdAt'];
              final String formattedDate = createdAt != null
                  ? DateFormat('d MMM yyyy').format(createdAt.toDate())
                  : 'Unknown Date';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                const Color(0xFF6A11CB).withAlpha(40),
                            child: Text(
                              reviewerName.isNotEmpty
                                  ? reviewerName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(color: Color(0xFF6A11CB)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(reviewerName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text(formattedDate,
                                    style:
                                        const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < rating
                                    ? Icons.star
                                    : Icons.star_border_outlined,
                                color: Colors.amber,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        comment,
                        style:
                            const TextStyle(fontSize: 15, color: Colors.black87),
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