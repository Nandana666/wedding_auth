// lib/booking_details_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookingDetailsPage extends StatelessWidget {
  final Map<String, dynamic> booking;
  final Map<String, dynamic> vendorData;

  const BookingDetailsPage({
    super.key,
    required this.booking,
    required this.vendorData,
  });

  @override
  Widget build(BuildContext context) {
    // Find the service associated with this booking
    final List<dynamic> services = vendorData['services'] ?? [];
    
    // Sanitize the booking title for a robust comparison
    final String bookedServiceTitle = booking['serviceTitle']?.toString().trim().toLowerCase() ?? '';

    // Use a robust search that ignores case and leading/trailing whitespace
    final bookedService = services.firstWhere(
      (service) {
        final serviceTitle = service['title']?.toString().trim().toLowerCase();
        return serviceTitle == bookedServiceTitle;
      },
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Client and Vendor Information
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Client: ${booking['userName'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Client Email: ${booking['userEmail'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Vendor: ${vendorData['name'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Location: ${vendorData['location'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Service Details Card
            // This card will now appear if a match is found
            if (bookedService != null)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bookedService['title'] ?? 'Service Details',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (bookedService['image_urls'] != null && bookedService['image_urls'].isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            bookedService['image_urls'][0],
                            fit: BoxFit.cover,
                            height: 200,
                            width: double.infinity,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        'Price: ₹${bookedService['price'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bookedService['description'] ?? 'No description.',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Booking and Payment Details
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Booking Information',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Event Date', _formatDate(booking['eventDate'])),
                    _buildDetailRow('Advance Payment', '₹${booking['advancePayment'] ?? 0}'),
                    _buildDetailRow('Payment Status', booking['paymentStatus'] ?? 'N/A'),
                    _buildDetailRow('Event Status', booking['eventStatus'] ?? 'N/A'),
                    _buildDetailRow('Booking Date & Time', _formatDateTime(booking['bookingDate'])),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "N/A";
    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year}";
  }

  String _formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) {
      return "N/A";
    }
    final dateTime = timestamp.toDate();
    return DateFormat('dd/MM/yyyy h:mm a').format(dateTime);
  }
}