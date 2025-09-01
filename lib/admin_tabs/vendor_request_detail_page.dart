// lib/admin_tabs/vendor_request_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class VendorRequestDetailPage extends StatefulWidget {
  final String vendorId;
  final Map<String, dynamic> vendorData;

  const VendorRequestDetailPage({
    super.key,
    required this.vendorId,
    required this.vendorData,
  });

  @override
  State<VendorRequestDetailPage> createState() =>
      _VendorRequestDetailPageState();
}

class _VendorRequestDetailPageState extends State<VendorRequestDetailPage> {
  bool _isProcessing = false;

  Future<void> _approveVendor() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await FirebaseFirestore.instance
          .collection('vendors')
          .doc(widget.vendorId)
          .update({
            'status': 'approved',
            'approvedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vendor approved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving vendor: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _declineVendor() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await FirebaseFirestore.instance
          .collection('vendors')
          .doc(widget.vendorId)
          .update({'status': 'declined'});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vendor has been declined.'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error declining vendor: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = widget.vendorData['image'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vendor Request Details"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.deepPurpleAccent,
                      backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                          ? NetworkImage(imageUrl)
                          : null,
                      child: (imageUrl == null || imageUrl.isEmpty)
                          ? Text(
                              widget.vendorData['name'] != null &&
                                      widget.vendorData['name'].isNotEmpty
                                  ? widget.vendorData['name'][0].toUpperCase()
                                  : 'V',
                              style: const TextStyle(
                                fontSize: 30,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.vendorData['name'] ?? "No Name",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.vendorData['category'] ??
                                "Category not specified",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: widget.vendorData.entries.map((entry) {
                    if (entry.value == null ||
                        entry.value.toString().isEmpty ||
                        [
                          'status',
                          'role',
                          'approvedAt',
                          'rating',
                          'image',
                        ].contains(entry.key)) {
                      return const SizedBox.shrink();
                    }

                    String displayValue;
                    if (entry.key == 'createdAt' && entry.value is Timestamp) {
                      final dateTime = (entry.value as Timestamp).toDate();
                      displayValue = DateFormat(
                        'dd MMM yyyy, hh:mm a',
                      ).format(dateTime);
                    } else {
                      displayValue = entry.value.toString();
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(
                              "${capitalize(entry.key)}:",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              displayValue,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _isProcessing
          ? const LinearProgressIndicator()
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: const Text(
                        'Decline',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: _declineVendor,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text(
                        'Approve',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: _approveVendor,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String capitalize(String s) =>
      s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '';
}
