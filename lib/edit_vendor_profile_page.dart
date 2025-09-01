// lib/edit_vendor_profile_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditVendorProfilePage extends StatefulWidget {
  const EditVendorProfilePage({super.key});

  @override
  State<EditVendorProfilePage> createState() => _EditVendorProfilePageState();
}

class _EditVendorProfilePageState extends State<EditVendorProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _locationController;
  // You can add more controllers for other fields like category, image URL, etc.

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _locationController = TextEditingController();
    _loadVendorData();
  }

  Future<void> _loadVendorData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('vendors').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        // Populate the text fields with existing data from Firestore
        setState(() {
          _nameController.text = data['name'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _priceController.text = data['price']?.toString() ?? '';
          _locationController.text = data['location'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false); // Stop loading even if no doc exists
      }
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      final user = FirebaseAuth.instance.currentUser;
      try {
        // Update the document in Firestore with the new data from the form
        await FirebaseFirestore.instance.collection('vendors').doc(user!.uid).update({
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'price': _priceController.text.trim(),
          'location': _locationController.text.trim(),
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);

      } catch (e) {
        setState(() => _errorMessage = 'Failed to save changes. Please try again.');
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Your Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Business Name', border: OutlineInputBorder()),
                      validator: (value) => value!.isEmpty ? 'Please enter your business name' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'About / Description', border: OutlineInputBorder()),
                      maxLines: 5,
                       validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Starting Price (e.g., 50000)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                       validator: (value) => value!.isEmpty ? 'Please enter a starting price' : null,
                    ),
                     const SizedBox(height: 20),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'Location (e.g., Kochi)', border: OutlineInputBorder()),
                       validator: (value) => value!.isEmpty ? 'Please enter your location' : null,
                    ),
                    const SizedBox(height: 30),

                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                      ),
                      
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF6A11CB),
                      ),
                      child: _isSaving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : const Text('Save Changes', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}