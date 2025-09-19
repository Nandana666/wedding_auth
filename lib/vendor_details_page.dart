// lib/vendor_details_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'chat_page.dart';
import 'fake_payment_page.dart'; // <-- IMPORT THE NEW PAGE

class VendorDetailsPage extends StatefulWidget {
  final String vendorId;
  final Map<String, dynamic> vendorData;
  final String? preSelectedCategory;

  const VendorDetailsPage({
    super.key,
    required this.vendorId,
    required this.vendorData,
    this.preSelectedCategory,
  });

  @override
  State<VendorDetailsPage> createState() => _VendorDetailsPageState();
}

class _VendorDetailsPageState extends State<VendorDetailsPage> {
  // ... all the existing state variables are fine ...
  bool isShortlisted = false;
  bool isLoading = true;
  Set<String> serviceCategories = {};

  @override
  void initState() {
    super.initState();
    _checkIfShortlisted();
    _extractServiceCategories();
  }

  // ... All methods from initState down to _processFakePayment are correct and unchanged ...
  @override
  void dispose() {
    super.dispose();
  }

  void _extractServiceCategories() {
    final List<dynamic> services = widget.vendorData['services'] ?? [];
    Set<String> categories = {};
    for (var service in services) {
      if (service is Map && service.containsKey('category')) {
        categories.add(service['category'] as String);
      }
    }
    setState(() {
      serviceCategories = categories;
    });
  }

  Future<void> _checkIfShortlisted() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => isLoading = false);
      }
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final List<dynamic> list = data['shortlistedVendors'] ?? [];
        if (mounted) {
          setState(() {
            isShortlisted = list.contains(widget.vendorId);
          });
        }
      }
    } catch (e) {
      // silent error
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _toggleShortlist() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save vendors.')),
      );
      return;
    }
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => isShortlisted = !isShortlisted);
    if (isShortlisted) {
      userRef.set({
        'shortlistedVendors': FieldValue.arrayUnion([widget.vendorId]),
      }, SetOptions(merge: true));
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Added to your shortlist!')),
      );
    } else {
      userRef.update({
        'shortlistedVendors': FieldValue.arrayRemove([widget.vendorId]),
      });
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Removed from your shortlist')),
      );
    }
  }

  Future<void> _startOrGoToChat() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to message vendors.')),
      );
      return;
    }
    final vendorId = widget.vendorId;
    final currentUserId = currentUser.uid;
    List<String> ids = [currentUserId, vendorId];
    ids.sort();
    String chatId = ids.join('_');
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      final userName = userDoc.data()?['name'] ?? 'New User';
      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'participants': [currentUserId, vendorId],
        'participantNames': {
          currentUserId: userName,
          vendorId: widget.vendorData['name'] ?? 'Vendor',
        },
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            chatId: chatId,
            recipientId: vendorId,
            recipientName: widget.vendorData['name'] ?? 'Vendor',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start chat. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createBookingRecord(DateTime eventDate, double amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userName = userDoc.data()?['name'] ?? 'Anonymous User';
    final String testPaymentId =
        'test_pay_${DateTime.now().millisecondsSinceEpoch}';

    final bookingData = {
      'vendorId': widget.vendorId,
      'vendorName': widget.vendorData['name'],
      'vendorCategory': widget.vendorData['categories']?.join(', ') ?? 'N/A',
      'userId': user.uid,
      'userName': userName,
      'bookingDate': Timestamp.now(),
      'eventDate': Timestamp.fromDate(eventDate),
      'advancePayment': amount,
      'paymentId': testPaymentId,
      'paymentStatus': 'Paid (Test)',
      'eventStatus': 'Upcoming',
    };

    final userBookingsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('bookings');
    final vendorBookingsRef = FirebaseFirestore.instance
        .collection('vendors')
        .doc(widget.vendorId)
        .collection('bookings');
    await userBookingsRef.add(bookingData);
    await vendorBookingsRef.add(bookingData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking Successful!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // --- THIS IS THE ONLY METHOD THAT CHANGES ---
  // We replace the AlertDialog with our new FakePaymentPage
  Future<void> _processFakePayment(DateTime eventDate, double amount) async {
    // Navigate to our new payment page and wait for a result.
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => FakePaymentPage(amount: amount)),
    );

    // If the page returned 'true', it means the payment was a success.
    if (result == true) {
      // Now we create the booking record, just like before.
      await _createBookingRecord(eventDate, amount);
    } else {
      // Handle the case where the user backs out of the payment page.
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Payment cancelled.')));
      }
    }
  }

  Future<void> _showBookingDialog() async {
    DateTime? selectedDate;
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Book This Vendor'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        selectedDate == null
                            ? 'Select Event Date'
                            : DateFormat(
                                'EEE, MMM d, yyyy',
                              ).format(selectedDate!),
                      ),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(
                            const Duration(days: 1),
                          ),
                          firstDate: DateTime.now().add(
                            const Duration(days: 1),
                          ),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null) {
                          setDialogState(() => selectedDate = pickedDate);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Advance Amount (₹)',
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null ||
                            double.parse(value) <= 0) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text('Proceed to Pay'),
                  onPressed: () {
                    if (selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select an event date.'),
                        ),
                      );
                      return;
                    }
                    if (formKey.currentState!.validate()) {
                      final amount = double.parse(amountController.text);
                      Navigator.of(context).pop();
                      // This now calls the method that opens our new page
                      _processFakePayment(selectedDate!, amount);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ... The rest of the file (build method and helpers) is completely unchanged ...
  @override
  Widget build(BuildContext context) {
    final String name = widget.vendorData['name'] ?? 'Vendor Name';
    final List<dynamic> categories =
        widget.vendorData['categories'] ?? ['Uncategorized'];
    final String description = widget.vendorData['description'] ?? '';
    final String location =
        widget.vendorData['location'] ?? 'Location not specified';
    final String contact = widget.vendorData['contact']?.toString() ?? '';
    final String email = widget.vendorData['email'] ?? '';
    final String imageUrl = widget.vendorData['company_logo'] ?? '';
    final List<dynamic> services = widget.vendorData['services'] ?? [];
    final categoriesToDisplay = widget.preSelectedCategory != null
        ? {widget.preSelectedCategory!}
        : serviceCategories;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            backgroundColor: const Color(0xFF6A11CB),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: Colors.grey),
                    )
                  : Container(
                      color: Colors.grey.shade400,
                      child: const Center(
                        child: Icon(
                          Icons.storefront,
                          color: Colors.white70,
                          size: 80,
                        ),
                      ),
                    ),
            ),
            actions: [
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              else
                IconButton(
                  icon: Icon(
                    isShortlisted ? Icons.favorite : Icons.favorite_border,
                    color: isShortlisted ? Colors.pinkAccent : Colors.white,
                    size: 28,
                  ),
                  onPressed: _toggleShortlist,
                  tooltip: 'Add to Shortlist',
                ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6A11CB).withAlpha(26),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            categories.join(', ').toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF6A11CB),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                color: Colors.grey.shade700,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const Divider(height: 40, thickness: 1),
                      const Text(
                        'About This Vendor',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                    const Divider(height: 40, thickness: 1),
                    const Text(
                      'Services Offered',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (services.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'No specific services listed by this vendor.',
                          ),
                        ),
                      )
                    else
                      ...categoriesToDisplay.map((category) {
                        final servicesInCategory = services
                            .where(
                              (service) =>
                                  service is Map &&
                                  service['category'] == category,
                            )
                            .toList();
                        if (servicesInCategory.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6A11CB),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...servicesInCategory.map(
                              (service) => _buildServiceCard(service),
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      }),
                    if (contact.isNotEmpty || email.isNotEmpty) ...[
                      const Divider(height: 40, thickness: 1),
                      const Text(
                        'Contact Info',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (contact.isNotEmpty)
                        _buildDetailRow(
                          icon: Icons.phone_outlined,
                          title: 'Phone Number',
                          content: contact,
                        ),
                      if (contact.isNotEmpty && email.isNotEmpty)
                        const SizedBox(height: 20),
                      if (email.isNotEmpty)
                        _buildDetailRow(
                          icon: Icons.email_outlined,
                          title: 'Email Address',
                          content: email,
                        ),
                    ],
                    const SizedBox(height: 40),
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              Icons.event_available,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Book Now',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: _showBookingDialog,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFFF472B6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              Icons.message_outlined,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Send a Message',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: _startOrGoToChat,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFF2575FC),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(dynamic service) {
    if (service is! Map<String, dynamic>) {
      return const SizedBox.shrink();
    }
    final List<dynamic> imageUrls = service['image_urls'] ?? [];
    final String title = service['title'] ?? 'No Title';
    final String description =
        service['description'] ?? 'No description available.';
    final String price = service['price']?.toString() ?? 'N/A';
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrls.isNotEmpty)
            SizedBox(
              height: 200,
              child: PageView.builder(
                itemCount: imageUrls.length,
                controller: PageController(),
                itemBuilder: (context, index) {
                  final url = imageUrls[index];
                  return Image.network(
                    url,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    'Starts from ₹$price',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6A11CB),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 18,
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
