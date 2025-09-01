// lib/vendor_details_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_page.dart';

class VendorDetailsPage extends StatefulWidget {
  final String vendorId;
  final Map<String, dynamic> vendorData;

  const VendorDetailsPage({
    super.key,
    required this.vendorId,
    required this.vendorData,
  });

  @override
  State<VendorDetailsPage> createState() => _VendorDetailsPageState();
}

class _VendorDetailsPageState extends State<VendorDetailsPage> {
  bool isShortlisted = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkIfShortlisted();
  }

  Future<void> _checkIfShortlisted() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
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
      // Error is handled silently
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

    if (isShortlisted) {
      userRef.update({
        'shortlistedVendors': FieldValue.arrayRemove([widget.vendorId]),
      });
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Removed from your shortlist')),
      );
    } else {
      userRef.update({
        'shortlistedVendors': FieldValue.arrayUnion([widget.vendorId]),
      });
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Added to your shortlist!')),
      );
    }

    setState(() {
      isShortlisted = !isShortlisted;
    });
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

    // Create a consistent chat ID by sorting UIDs
    List<String> ids = [currentUserId, vendorId];
    ids.sort();
    String chatId = ids.join('_');

    final chatDoc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .get();

    if (!chatDoc.exists) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      final userName =
          (userDoc.data() as Map<String, dynamic>)['name'] ?? 'New User';

      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'participants': [currentUserId, vendorId],
        'participantNames': {
          currentUserId: userName,
          vendorId: widget.vendorData['name'] ?? 'Vendor',
        },
        'lastMessage': '',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });
    }

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
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.vendorData['name'] ?? 'Vendor Name';
    final String category = widget.vendorData['category'] ?? 'Uncategorized';
    final String description =
        widget.vendorData['description'] ?? 'No description available.';
    final String location =
        widget.vendorData['location'] ?? 'Location not specified';
    final String contact = widget.vendorData['contact']?.toString() ?? '';
    final String email = widget.vendorData['email'] ?? '';
    final String imageUrl =
        widget.vendorData['image'] ?? 'https://via.placeholder.com/400x250';

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
              background: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                color: const Color.fromARGB(102, 0, 0, 0),
                colorBlendMode: BlendMode.darken,
              ),
            ),
            actions: [
              if (!isLoading)
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
                      children: [
                        Text(
                          category.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF6A11CB),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                color: Colors.grey.shade700,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                location,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'About this Vendor',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                    const Divider(height: 40, thickness: 1),
                    const Text(
                      'Contact & Info',
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
                    if (contact.isNotEmpty) const SizedBox(height: 20),
                    if (email.isNotEmpty)
                      _buildDetailRow(
                        icon: Icons.email_outlined,
                        title: 'Email Address',
                        content: email,
                      ),
                    const Divider(height: 40, thickness: 1),
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
