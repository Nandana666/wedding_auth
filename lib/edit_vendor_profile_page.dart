// lib/edit_vendor_profile_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class EditVendorProfilePage extends StatefulWidget {
  const EditVendorProfilePage({super.key});

  @override
  State<EditVendorProfilePage> createState() => _EditVendorProfilePageState();
}

class _EditVendorProfilePageState extends State<EditVendorProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _locationController;

  File? _companyLogoFile;
  String? _networkCompanyLogoUrl;

  List<Map<String, dynamic>> _services = [];
  List<GlobalKey<FormState>> _serviceFormKeys = [];

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _locationController = TextEditingController();
    _loadVendorData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadVendorData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('vendors')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _nameController.text = data['name'] ?? '';
            _locationController.text = data['location'] ?? '';
            _networkCompanyLogoUrl = data['company_logo'];

            _services = List<Map<String, dynamic>>.from(data['services'] ?? []);
            _serviceFormKeys = List.generate(
              _services.length,
              (index) => GlobalKey<FormState>(),
            );
          });
        }
      } catch (e) {
        setState(() => _errorMessage = e.toString());
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickCompanyLogo() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() {
        _companyLogoFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    final cloudinary = CloudinaryPublic(
      'dc9kib0cr', // Replace with your Cloudinary cloud name
      'ml_default', // Replace with your upload preset
      cache: false,
    );

    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      return null;
    }
  }

  void _addService() {
    setState(() {
      _services.add({
        'title': '',
        'description': '',
        'price': '',
        'image_url': '',
        'image_file': null,
      });
      _serviceFormKeys.add(GlobalKey<FormState>());
    });
  }

  void _removeService(int index) {
    setState(() {
      _services.removeAt(index);
      _serviceFormKeys.removeAt(index);
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    for (var key in _serviceFormKeys) {
      if (!key.currentState!.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all service details.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser;
    List<Map<String, dynamic>> servicesToSave = [];
    String? logoUrlToSave;

    try {
      // 1. Upload company logo if a new one was picked
      if (_companyLogoFile != null) {
        logoUrlToSave = await _uploadImage(_companyLogoFile!);
        if (logoUrlToSave == null) {
          throw Exception("Company logo upload failed. Please try again.");
        }
      } else {
        logoUrlToSave = _networkCompanyLogoUrl;
      }

      // 2. Upload service images
      for (var service in _services) {
        String? imageUrl = service['image_url'];
        File? imageFile = service['image_file'];

        if (imageFile != null) {
          imageUrl = await _uploadImage(imageFile);
          if (imageUrl == null) {
            throw Exception("Image upload failed for a service.");
          }
        }
        servicesToSave.add({
          'title': service['title'],
          'description': service['description'],
          'price': service['price'],
          'image_url': imageUrl ?? '',
        });
      }

      // 3. Update Firestore document
      await FirebaseFirestore.instance
          .collection('vendors')
          .doc(user!.uid)
          .set({
            'name': _nameController.text.trim(),
            'location': _locationController.text.trim(),
            'company_logo': logoUrlToSave ?? '',
            'services': servicesToSave,
            'status': 'pending_approval',
          }, SetOptions(merge: true));

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
                    // --- COMPANY LOGO UPLOAD ---
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: _companyLogoFile != null
                                ? FileImage(_companyLogoFile!) as ImageProvider
                                : (_networkCompanyLogoUrl != null &&
                                          _networkCompanyLogoUrl!.isNotEmpty
                                      ? NetworkImage(_networkCompanyLogoUrl!)
                                            as ImageProvider
                                      : null),
                            child:
                                (_companyLogoFile == null &&
                                    (_networkCompanyLogoUrl == null ||
                                        _networkCompanyLogoUrl!.isEmpty))
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
                              onTap: _pickCompanyLogo,
                              child: const CircleAvatar(
                                radius: 20,
                                backgroundColor: Color(0xFF6A11CB),
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

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Services',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addService,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A11CB),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Add More'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // FIX 1: Removed .toList()
                    ..._services.asMap().entries.map((entry) {
                      int index = entry.key;
                      Map<String, dynamic> service = entry.value;
                      return ServiceForm(
                        key: _serviceFormKeys[index],
                        service: service,
                        onImagePick: (File? image) {
                          setState(() {
                            _services[index]['image_file'] = image;
                          });
                        },
                        onTitleChanged: (String title) {
                          _services[index]['title'] = title;
                        },
                        onDescriptionChanged: (String description) {
                          _services[index]['description'] = description;
                        },
                        onPriceChanged: (String price) {
                          _services[index]['price'] = price;
                        },
                        onRemove: () => _removeService(index),
                      );
                    }),

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

class ServiceForm extends StatefulWidget {
  final Map<String, dynamic> service;
  final Function(File?) onImagePick;
  final Function(String) onTitleChanged;
  final Function(String) onDescriptionChanged;
  final Function(String) onPriceChanged;
  final VoidCallback onRemove;

  const ServiceForm({
    required Key key,
    required this.service,
    required this.onImagePick,
    required this.onTitleChanged,
    required this.onDescriptionChanged,
    required this.onPriceChanged,
    required this.onRemove,
  }) : super(key: key);

  @override
  // FIX 2: Changed return type from private _ServiceFormState to public State<ServiceForm>
  State<ServiceForm> createState() => _ServiceFormState();
}

class _ServiceFormState extends State<ServiceForm> {
  final ImagePicker _picker = ImagePicker();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.service['title']);
    _descriptionController = TextEditingController(
      text: widget.service['description'],
    );
    _priceController = TextEditingController(
      text: widget.service['price'].toString(),
    );
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      widget.onImagePick(File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: widget.key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: widget.onRemove,
                ),
              ),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: widget.service['image_file'] != null
                      ? Image.file(
                          widget.service['image_file'],
                          fit: BoxFit.cover,
                        )
                      : (widget.service['image_url'] != null &&
                                widget.service['image_url'].isNotEmpty
                            ? Image.network(
                                widget.service['image_url'],
                                fit: BoxFit.cover,
                              )
                            : const Icon(
                                Icons.add_a_photo,
                                size: 50,
                                color: Colors.grey,
                              )),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Service Title'),
                onChanged: widget.onTitleChanged,
                validator: (value) =>
                    value!.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                onChanged: widget.onDescriptionChanged,
                maxLines: 3,
                validator: (value) =>
                    value!.isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                onChanged: widget.onPriceChanged,
                validator: (value) =>
                    value!.isEmpty ? 'Price is required' : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
