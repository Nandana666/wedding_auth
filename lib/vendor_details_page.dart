// lib/vendor_details_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'chat_page.dart';
import 'fake_payment_page.dart';

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
  bool isShortlisted = false;
  bool isLoading = true;
  Set<String> serviceCategories = {};

  @override
  void initState() {
    super.initState();
    _checkIfShortlisted();
    _extractServiceCategories();
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
      if (mounted) setState(() => isLoading = false);
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
    } catch (_) {
      // silent error
    } finally {
      if (mounted) setState(() => isLoading = false);
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
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
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

  Future<void> _createBookingRecord(
      DateTime eventDate, double amount, String serviceTitle) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userName = userDoc.data()?['name'] ?? 'Anonymous User';
    final userEmail = user.email ?? 'N/A';
    final String testPaymentId =
        'test_pay_${DateTime.now().millisecondsSinceEpoch}';

    final bookingData = {
      'vendorId': widget.vendorId,
      'vendorName': widget.vendorData['name'],
      'vendorCategory': widget.vendorData['categories']?.join(', ') ?? 'N/A',
      'userId': user.uid,
      'userName': userName,
      'userEmail': userEmail,
      'serviceTitle': serviceTitle,
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

  Future<void> _processFakePayment(
      DateTime eventDate, double amount, String serviceTitle) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => FakePaymentPage(
                amount: amount,
                merchantName: widget.vendorData['name'] ?? 'Vendor',
              )),
    );

    if (result == true) {
      await _createBookingRecord(eventDate, amount, serviceTitle);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Payment cancelled.')));
      }
    }
  }

  Future<void> _showBookingDialogForService(
      String serviceTitle, double amount) async {
    DateTime? selectedDate;
    final amountController =
        TextEditingController(text: amount.toStringAsFixed(2));
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Book $serviceTitle'),
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
                            : DateFormat('EEE, MMM d, yyyy')
                                .format(selectedDate!),
                      ),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate:
                              DateTime.now().add(const Duration(days: 1)),
                          firstDate:
                              DateTime.now().add(const Duration(days: 1)),
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
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
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
                            content: Text('Please select an event date.')),
                      );
                      return;
                    }
                    if (formKey.currentState!.validate()) {
                      final newAmount = double.parse(amountController.text);
                      Navigator.of(context).pop();
                      _processFakePayment(selectedDate!, newAmount, serviceTitle);
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

  void _showRatingDialog(String serviceTitle) {
    double selectedRating = 0;
    final reviewController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit a review.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Rate $serviceTitle'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            selectedRating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Write a review',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedRating == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a rating.')),
                  );
                  return;
                }

                final reviewText = reviewController.text.trim();

                await FirebaseFirestore.instance
                    .collection('vendors')
                    .doc(widget.vendorId)
                    .collection('services')
                    .doc(serviceTitle)
                    .collection('reviews')
                    .add({
                  'userId': user.uid,
                  'rating': selectedRating,
                  'review': reviewText,
                  'timestamp': FieldValue.serverTimestamp(),
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thank you for your feedback!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

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
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startOrGoToChat,
        label: const Text(
          'Message Vendor',
          style: TextStyle(color: Colors.white),
        ),
        icon: const Icon(Icons.chat, color: Colors.white),
        backgroundColor: const Color(0xFF6A11CB),
      ),
    );
  }

  // UPDATED METHOD: _buildServiceCard to handle multiple images
  Widget _buildServiceCard(Map<String, dynamic> service) {
    final String title = service['title'] ?? 'Service';
    final String price = service['price']?.toString() ?? '0';
    final String description = service['description'] ?? '';
    final List<dynamic> imageUrls = service['imageUrls'] ?? []; // **Changed to a list**

    double servicePrice = 0;
    try {
      servicePrice = double.parse(price);
    } catch (_) {}

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrls.isNotEmpty)
            SizedBox(
              height: 200, // Fixed height for the PageView
              child: PageView.builder(
                itemCount: imageUrls.length,
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      imageUrls[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                            ),
                          ),
                    ),
                  );
                },
              ),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Center(
                child: Icon(Icons.photo_library, size: 50, color: Colors.grey),
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Starts from ₹$price',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A11CB),
                      ),
                    ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            _showBookingDialogForService(title, servicePrice);
                          },
                          icon: const Icon(Icons.event_available, size: 18),
                          label: const Text('Book'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF472B6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            _showRatingDialog(title);
                          },
                          icon: const Icon(Icons.star_rate, size: 18),
                          label: const Text('Rate'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2575FC),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF6A11CB)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 5),
              Text(
                content,
                style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}