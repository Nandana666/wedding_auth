// lib/user_dashboard.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// NOTE: Ensure these files exist in your project structure
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
                  _buildSectionHeader('My Shortlisted Vendors'),
                  const SizedBox(height: 10),
                  shortlistedVendorIds.isEmpty
                      ? _buildEmptyShortlistCard()
                      : _buildShortlistedVendorsList(shortlistedVendorIds),
                  const SizedBox(height: 20),
                  _buildSectionHeader('My Bookings / History'),
                  const SizedBox(height: 10),
                  _buildBookingHistory(
                    context,
                    currentUser.uid,
                  ), // Pass context
                  const SizedBox(height: 20),
                  _buildSectionHeader('Account'),
                  const SizedBox(height: 10),
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
                  _buildMenuItem(
                    context: context,
                    icon: Icons.logout,
                    title: 'Log Out',
                    color: Colors.red.shade400,
                    onTap: () async {
                      await AuthService().signOut();
                      if (!context.mounted) return;
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

  Widget _buildBookingHistory(BuildContext context, String userId) {
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                "No bookings yet.",
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
            final bookingDoc = bookings[index];
            final booking = bookingDoc.data() as Map<String, dynamic>;

            final eventDate = (booking['eventDate'] as Timestamp?)?.toDate();
            final bool hasBeenReviewed = booking['hasBeenReviewed'] ?? false;
            final bool isEventOver =
                eventDate != null && eventDate.isBefore(DateTime.now());

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking['vendorName'] ?? 'Vendor',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow("Category", booking['vendorCategory'] ?? 'N/A'),
                    _buildDetailRow("Event Date", _formatDate(booking['eventDate'])),
                    _buildDetailRow(
                      "Category",
                      booking['vendorCategory'] ?? 'N/A',
                    ),
                    _buildDetailRow(
                      "Event Date",
                      _formatDate(booking['eventDate']),
                    ),
                    _buildDetailRow(
                      "Advance Paid",
                      "₹${booking['advancePayment'] ?? 0}",
                    ),

                    const Divider(height: 20),

                    if (isEventOver && !hasBeenReviewed)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showReviewDialog(
                              context,
                              bookingId: bookingDoc.id,
                              vendorId: booking['vendorId'],
                              vendorName: booking['vendorName'],
                            );
                          },
                          icon: const Icon(Icons.rate_review_outlined, color: Colors.white),
                          label: const Text('Add a Review', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                        ),
                      )
                    else if (hasBeenReviewed)
                      const Center(
                        child: Text(
                          "✔ Reviewed",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showCancelConfirmationDialog(
                            context,
                            bookingDoc.id,
                            booking['vendorName'] ?? 'Vendor',
                            advancePaid,
                          ),
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Cancel Booking'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- THIS IS THE FIXED WIDGET ---
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label:", style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.right, // Aligns text to the right
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmationDialog(
    BuildContext context,
    String bookingId,
    String vendorName,
    double advancePaid,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Confirm Cancellation"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  "Are you sure you want to cancel your booking with ${vendorName}?"),
              const SizedBox(height: 10),
              Text(
                "Advance Payment Paid: ₹${advancePaid.toStringAsFixed(0)}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.orange),
              ),
              const SizedBox(height: 10),
              const Text(
                "Note: Cancellations may be subject to the vendor's refund policy.",
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
              const Text(
                "The refunded amount (if any) will be credited to your account within 1-2 working days.",
                style: TextStyle(fontSize: 12, color: Colors.green),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Keep Booking"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Yes, Cancel",
                  style: TextStyle(color: Colors.white)),
              onPressed: () {
                _cancelBooking(context, bookingId);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelBooking(BuildContext context, String bookingId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('bookings')
          .doc(bookingId)
          .update({'isCancelled': true});

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Booking successfully cancelled.'),
            backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to cancel booking: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  void _showReviewDialog(
    BuildContext context, {
    required String bookingId,
    required String vendorId,
    required String vendorName,
  }) {
    showDialog(
      context: context,
      builder: (_) => ReviewDialog(
        bookingId: bookingId,
        vendorId: vendorId,
        vendorName: vendorName,
      ),
    );
  }

  // ... (The rest of the file is unchanged) ...
  _buildProfileHeader(BuildContext context, Map<String, dynamic> userData) {
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
    if (vendorIds.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vendors')
          .where(FieldPath.documentId, whereIn: vendorIds)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final vendors = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: vendors.length,
          itemBuilder: (context, index) {
            final vendorData = vendors[index].data() as Map<String, dynamic>;
            final vendorId = vendors[index].id;
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
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: onTap != null
            ? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)
            : null,
      ),
    );
  }
}

// The ReviewDialog widget remains the same and is correct
class ReviewDialog extends StatefulWidget {
  final String bookingId;
  final String vendorId;
  final String vendorName;

  const ReviewDialog({
    super.key,
    required this.bookingId,
    required this.vendorId,
    required this.vendorName,
  });

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  double _rating = 0;
  final _commentController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userName = userDoc.data()?['name'] ?? 'Anonymous';

      final reviewData = {
        'userId': user.uid,
        'userName': userName,
        'vendorId': widget.vendorId,
        'vendorName': widget.vendorName,
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      final batch = FirebaseFirestore.instance.batch();
      final reviewRef = FirebaseFirestore.instance.collection('reviews').doc();
      batch.set(reviewRef, reviewData);

      final userBookingRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('bookings')
          .doc(widget.bookingId);
      batch.update(userBookingRef, {'hasBeenReviewed': true});

      await batch.commit();

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your review!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit review: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Review ${widget.vendorName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tap a star to rate:'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    setState(() {
                      _rating = index + 1.0;
                    });
                  },
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 35,
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Add a comment (optional)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitReview,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}