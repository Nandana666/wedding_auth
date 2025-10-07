// lib/my_bookings_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Assuming ReviewDialog, _showCancelConfirmationDialog, and _cancelBooking
// are available, perhaps by moving them here or importing the UserDashboard.dart file.
// For this example, I will include placeholder functions to ensure the code runs.

class MyBookingsPage extends StatelessWidget {
  final String userId;

  const MyBookingsPage({super.key, required this.userId});

  // Helper functions used in the booking card
  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "N/A";
    final date = timestamp.toDate();
    // Use DateFormat from intl package for clean date formatting
    return DateFormat('dd/MM/yyyy').format(date);
  }

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
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // Placeholder for the Review Dialog (you should implement this fully or import it)
  void _showReviewDialog(
    BuildContext context, {
    required String bookingId,
    required String vendorId,
    required String vendorName,
  }) {
    // Implement the actual ReviewDialog show logic here
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review dialog functionality is here!')));
  }

  // Placeholder for the Cancel Confirmation Dialog (you should implement this fully or import it)
  void _showCancelConfirmationDialog(
    BuildContext context,
    String bookingId,
    String vendorName,
    double advancePaid,
  ) {
    // Implement the actual cancel dialog show logic here
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cancel dialog for $vendorName is here!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Bookings"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF472B6), Color(0xFF60A5FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
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
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  "You have no bookings yet. Find a vendor to get started!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            );
          }

          final bookings = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final bookingDoc = bookings[index];
              final booking = bookingDoc.data() as Map<String, dynamic>;

              final eventDate = (booking['eventDate'] as Timestamp?)?.toDate();
              final bool hasBeenReviewed = booking['hasBeenReviewed'] ?? false;
              final bool isCancelled = booking['isCancelled'] ?? false;
              
              // Check if event is over
              final bool isEventOver =
                  eventDate != null && eventDate.isBefore(DateTime.now());
              final double advancePaid =
                  (booking['advancePayment'] ?? 0).toDouble();

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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isCancelled ? Colors.red.shade700 : Colors.black,
                          decoration: isCancelled ? TextDecoration.lineThrough : TextDecoration.none,
                        ),
                      ),
                      Text(
                        isCancelled ? 'Status: Cancelled' : 'Status: Confirmed',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCancelled ? Colors.red.shade700 : Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                          "Category", booking['vendorCategory'] ?? 'N/A'),
                      _buildDetailRow(
                          "Service", booking['serviceTitle'] ?? 'N/A'),
                      _buildDetailRow(
                          "Event Date", _formatDate(booking['eventDate'])),
                      _buildDetailRow("Amount Paid", "₹${advancePaid.toStringAsFixed(0)}"),
                      const Divider(height: 20),
                      
                      // Action Buttons
                      if (isCancelled)
                        Center(
                          child: Text(
                            "This booking was cancelled.",
                            style: TextStyle(color: Colors.red.shade400, fontStyle: FontStyle.italic),
                          ),
                        )
                      else if (isEventOver && !hasBeenReviewed)
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
                            icon: const Icon(Icons.rate_review_outlined,
                                color: Colors.white),
                            label: const Text('Add a Review',
                                style: TextStyle(color: Colors.white)),
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
                        // Cancel button for future bookings
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
      ),
    );
  }
}