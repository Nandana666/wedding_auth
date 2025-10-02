// lib/booking_details_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookingDetailsPage extends StatelessWidget {
  // CHANGED: This now accepts a List of bookings for a single client
  final List<Map<String, dynamic>> clientBookings;
  final Map<String, dynamic> vendorData;

  const BookingDetailsPage({
    super.key,
    // Renamed the parameter for clarity
    required this.clientBookings,
    required this.vendorData,
  });

  @override
  Widget build(BuildContext context) {
    if (clientBookings.isEmpty) {
      return const Scaffold(
        appBar: null, // Avoid double AppBar if ClientBookingsPage already exists
        body: Center(child: Text("No bookings found for this client.")),
      );
    }

    // Use the first booking to get consistent client details
    final firstBooking = clientBookings.first;
    final clientName = firstBooking['userName'] ?? 'N/A';
    final clientEmail = firstBooking['userEmail'] ?? 'N/A';
    final vendorName = vendorData['name'] ?? 'N/A';
    final vendorLocation = vendorData['location'] ?? 'N/A';


    return Scaffold(
      appBar: AppBar(
        title: Text('$clientName\'s Bookings (${clientBookings.length})'),
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
            // --- Client and Vendor Information (Static at the top) ---
            _buildClientHeaderCard(clientName, clientEmail, vendorName, vendorLocation),
            const SizedBox(height: 16),
            
            // --- Dynamically build cards for each booking/service ---
            ...clientBookings.map((booking) {
              return _buildBookingCard(context, booking);
            }).toList(),
            // --------------------------------------------------------
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildClientHeaderCard(String clientName, String clientEmail, String vendorName, String vendorLocation) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Client: $clientName',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF6A11CB)),
            ),
            const SizedBox(height: 8),
            Text(
              'Email: $clientEmail',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const Divider(height: 24),
            Text(
              'Vendor: $vendorName',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              'Location: $vendorLocation',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Map<String, dynamic> booking) {
    // Find the service associated with this booking (Optional, but good for robust display)
    final List<dynamic> services = vendorData['services'] ?? [];
    final String bookedServiceTitle = booking['serviceTitle']?.toString().trim().toLowerCase() ?? '';
    final bookedService = services.firstWhere(
      (service) {
        final serviceTitle = service['title']?.toString().trim().toLowerCase();
        return serviceTitle == bookedServiceTitle;
      },
      orElse: () => null,
    );

    // Extract the image URLs safely
    final List<dynamic> imageUrls = bookedService?['image_urls'] ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Service Title and Status ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      booking['serviceTitle'] ?? 'Unnamed Service',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildStatusBadge(booking['eventStatus'] ?? 'N/A'),
                ],
              ),
              const Divider(height: 20),
              
              // --- Service Image CAROUSEL (Updated Block) ---
              if (imageUrls.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: SizedBox(
                    height: 150, // Fixed height for the carousel
                    child: StatefulBuilder(
                      builder: (context, setState) {
                        int currentPage = 0;
                        PageController pageController = PageController();
        
                        // Listener to update the index for the dots
                        // Note: This needs to be disposed, but for a simple non-global widget like this, it's often omitted for brevity.
                        // A more robust solution would use a dedicated StatefulWidget.
                        pageController.addListener(() {
                          int newPage = pageController.page?.round() ?? 0;
                          // Use a slight delay before checking to ensure listener doesn't cause excessive setState calls
                          Future.delayed(Duration.zero, () {
                            if (!context.mounted) return;
                            if (newPage != currentPage) {
                              setState(() {
                                currentPage = newPage;
                              });
                            }
                          });
                        });

                        return Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            // 1. Page View (Image Swiping)
                            PageView.builder(
                              controller: pageController,
                              itemCount: imageUrls.length,
                              itemBuilder: (context, index) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imageUrls[index],
                                    fit: BoxFit.cover,
                                    height: 150,
                                    width: double.infinity,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      height: 150,
                                      color: Colors.grey.shade300,
                                      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                                    ),
                                  ),
                                );
                              },
                            ),

                            // 2. Page Indicators (Dots)
                            if (imageUrls.length > 1)
                              Positioned(
                                bottom: 8,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: imageUrls.asMap().entries.map((entry) {
                                    bool isCurrentPage = entry.key == currentPage;
                                    return Container(
                                      width: isCurrentPage ? 8.0 : 6.0,
                                      height: isCurrentPage ? 8.0 : 6.0,
                                      margin: const EdgeInsets.symmetric(horizontal: 3.0),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isCurrentPage ? Colors.white : Colors.white54,
                                        border: Border.all(
                                          color: Colors.black.withOpacity(0.2),
                                          width: 0.5,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        );
                      }
                    ),
                  ),
                ),
              // -----------------------------------------------------

              // --- Booking Details ---
              _buildDetailRow('Booked For', booking['serviceTitle'] ?? 'N/A'),
              _buildDetailRow('Event Date', _formatDate(booking['eventDate'])),
              _buildDetailRow('Booking Date', _formatDateTime(booking['bookingDate'])),
              _buildDetailRow('Price', '₹${bookedService?['price'] ?? 'N/A'}'), // Use actual service price if found
              _buildDetailRow('Advance Paid', '₹${booking['advancePayment'] ?? 0}'),
              _buildDetailRow('Payment Status', booking['paymentStatus'] ?? 'N/A'),
            ],
          ),
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

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'confirmed':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.amber.shade700;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "N/A";
    final date = timestamp.toDate();
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) {
      return "N/A";
    }
    final dateTime = timestamp.toDate();
    return DateFormat('dd/MM/yyyy h:mm a').format(dateTime);
  }
}