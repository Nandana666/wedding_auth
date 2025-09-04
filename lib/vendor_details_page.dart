// lib/vendor_details_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_page.dart';

class VendorDetailsPage extends StatefulWidget {
  final String vendorId;
  final Map<String, dynamic> vendorData;
  final String? preSelectedCategory; // New optional parameter

  const VendorDetailsPage({
    super.key,
    required this.vendorId,
    required this.vendorData,
    this.preSelectedCategory, // Initialize the new parameter
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
      // Error is handled silently for a better user experience
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

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
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

      await FirebaseFirestore.instance.collection('chats').doc(chatId).set(
        {
          'participants': [currentUserId, vendorId],
          'participantNames': {
            currentUserId: userName,
            vendorId: widget.vendorData['name'] ?? 'Vendor',
          },
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

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

    // Determine which categories to display
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
                  shadows: [Shadow(blurRadius: 5, color: Colors.black54)],
                ),
              ),
              background: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      color: Colors.black.withAlpha(102),
                      colorBlendMode: BlendMode.darken,
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
                            .where((service) =>
                                service is Map && service['category'] == category)
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
                            ...servicesInCategory.map((service) {
                              return _buildServiceCard(service);
                            }),
                            const SizedBox(height: 24),
                          ],
                        );
                      }).toList(),
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
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(dynamic service) {
    if (service is! Map<String, dynamic>) return const SizedBox.shrink();
    final String imageUrl = service['image_url'] ?? '';
    final String title = service['title'] ?? 'No Title';
    final String description =
        service['description'] ?? 'No description available.';
    final String price = service['price']?.toString() ?? 'N/A';
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 180,
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
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