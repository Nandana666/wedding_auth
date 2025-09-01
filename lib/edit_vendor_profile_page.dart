// lib/edit_vendor_profile_page.dart

import 'dart:io'; // Required for the File type
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // Import for picking images
import 'package:cloudinary_public/cloudinary_public.dart'; // Import for Cloudinary uploads

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
  String? _selectedCategory;

  // --- NEW STATE VARIABLES FOR IMAGE HANDLING ---
  File? _imageFile; // To hold the newly picked image file
  final ImagePicker _picker = ImagePicker();
  String? _networkImageUrl; // To hold the existing image URL from Firestore

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  final List<String> _categories = [
    'Makeup',
    'Catering',
    'Photography',
    'Decor',
    'Venues',
    'Packages',
  ];

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
      final doc = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _priceController.text = data['price']?.toString() ?? '';
          _locationController.text = data['location'] ?? '';
          _networkImageUrl = data['image']; // Load existing image URL

          final categoryFromServer = data['category'];
          if (_categories.contains(categoryFromServer)) {
            _selectedCategory = categoryFromServer;
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- FUNCTION TO PICK AN IMAGE FROM THE GALLERY ---
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // --- FUNCTION TO UPLOAD THE IMAGE TO CLOUDINARY ---
  Future<String?> _uploadImage(File image) async {
    // !!! IMPORTANT: Replace with your Cloudinary details !!!
    final cloudinary = CloudinaryPublic(
      'dc9kib0cr',
      'ml_default',
      cache: false,
    );

    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl; // This is the public URL of the uploaded image
    } catch (e) {
      // Handle upload error
      return null;
    }
  }

  // --- UPDATED SAVE FUNCTION ---
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a service category.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser;
    String? imageUrlToSave;

    try {
      // 1. If a new image was picked, upload it.
      if (_imageFile != null) {
        imageUrlToSave = await _uploadImage(_imageFile!);
        if (imageUrlToSave == null) {
          throw Exception("Image upload failed. Please try again.");
        }
      } else {
        // Otherwise, keep the existing image URL.
        imageUrlToSave = _networkImageUrl;
      }

      // 2. Update the document in Firestore.
      await FirebaseFirestore.instance
          .collection('vendors')
          .doc(user!.uid)
          .update({
            'name': _nameController.text.trim(),
            'description': _descriptionController.text.trim(),
            'price': _priceController.text.trim(),
            'location': _locationController.text.trim(),
            'category': _selectedCategory,
            'image': imageUrlToSave ?? '', // Save the new or existing URL
            'status': 'pending_approval',
          });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile submitted for admin review!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
      appBar: AppBar(title: const Text('Complete Your Vendor Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- IMAGE PICKER UI ---
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : (_networkImageUrl != null &&
                                              _networkImageUrl!.isNotEmpty
                                          ? NetworkImage(_networkImageUrl!)
                                          : null)
                                      as ImageProvider?,
                            child:
                                (_imageFile == null &&
                                    (_networkImageUrl == null ||
                                        _networkImageUrl!.isEmpty))
                                ? Icon(
                                    Icons.storefront,
                                    size: 60,
                                    color: Colors.grey.shade400,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: const CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.deepPurple,
                                child: Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- FORM FIELDS ---
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Business Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty
                          ? 'Please enter your business name'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      hint: const Text('Select Service Category'),
                      decoration: const InputDecoration(
                        labelText: 'Service Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (newValue) =>
                          setState(() => _selectedCategory = newValue),
                      validator: (value) =>
                          value == null ? 'Please select a category' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'About / Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a description' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Starting Price (e.g., 50000)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty
                          ? 'Please enter a starting price'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location (e.g., Kochi)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter your location' : null,
                    ),
                    const SizedBox(height: 30),

                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF6A11CB),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              'Submit for Review',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
