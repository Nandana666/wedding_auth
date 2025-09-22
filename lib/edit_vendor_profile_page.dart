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
  late TextEditingController _descriptionController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  Set<String> _selectedCategories = {};
  final Map<String, List<String>> _subcategories = {
    'Makeup': ['Bridal', 'Party', 'Casual'],
    'Catering': ['Vegetarian', 'Non-Vegetarian', 'Desserts'],
    'Photography': ['Wedding', 'Pre-wedding', 'Events'],
    'Decor': ['Indoor', 'Outdoor', 'Theme'],
    'Venues': ['Hall', 'Garden', 'Beach'],
    'Packages': ['Silver', 'Gold', 'Platinum'],
  };
  final List<String> _categories = [
    'Makeup',
    'Catering',
    'Photography',
    'Decor',
    'Venues',
    'Packages',
  ];

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
    _descriptionController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _loadVendorData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
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
            _descriptionController.text = data['description'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _addressController.text = data['address'] ?? '';
            _networkCompanyLogoUrl = data['company_logo'];

            final categoryFromServer = data['categories'];
            if (categoryFromServer is List) {
              _selectedCategories = Set<String>.from(categoryFromServer);
            } else if (categoryFromServer is String) {
              _selectedCategories = {categoryFromServer};
            }

            _services = List<Map<String, dynamic>>.from(data['services'] ?? []);
            for (var service in _services) {
              service['image_urls'] = List<String>.from(service['image_urls'] ?? []);
              service['image_files'] = <File>[];
            }
            _serviceFormKeys =
                List.generate(_services.length, (index) => GlobalKey<FormState>());
          });
        }
      } catch (e) {
        setState(() => _errorMessage = "Failed to load data: $e");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickCompanyLogo() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _companyLogoFile = File(pickedFile.path));
    }
  }

  Future<String?> _uploadImage(File image) async {
    final cloudinary = CloudinaryPublic('dc9kib0cr', 'ml_default', cache: false);
    try {
      CloudinaryResponse response =
          await cloudinary.uploadFile(CloudinaryFile.fromFile(image.path, resourceType: CloudinaryResourceType.Image));
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
        'category': null,
        'subcategory': null,
        'image_urls': [],
        'image_files': [],
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
    if (!_formKey.currentState!.validate() || _selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill all required details.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    for (var key in _serviceFormKeys) {
      if (!key.currentState!.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please fill all required service details.'),
          backgroundColor: Colors.red,
        ));
        return;
      }
    }

    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = "Authentication error. Please log in again.";
        _isSaving = false;
      });
      return;
    }

    try {
      String? logoUrlToSave = _networkCompanyLogoUrl;
      if (_companyLogoFile != null) {
        logoUrlToSave = await _uploadImage(_companyLogoFile!);
        if (logoUrlToSave == null) throw Exception("Company logo upload failed.");
      }

      List<Map<String, dynamic>> servicesToSave = [];
      for (var service in _services) {
        List<String> uploadedUrls = [];
        for (File file in (service['image_files'] as List<File>)) {
          final url = await _uploadImage(file);
          if (url != null) uploadedUrls.add(url);
        }
        uploadedUrls.addAll(List<String>.from(service['image_urls'] ?? []));
        servicesToSave.add({
          'title': service['title'],
          'description': service['description'],
          'price': service['price'],
          'category': service['category'],
          'subcategory': service['subcategory'],
          'image_urls': uploadedUrls,
        });
      }

      await FirebaseFirestore.instance.collection('vendors').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'categories': _selectedCategories.toList(),
        'company_logo': logoUrlToSave ?? '',
        'services': servicesToSave,
        'status': 'pending_approval',
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profile submitted for admin review!'),
        backgroundColor: Colors.green,
      ));
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
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: _companyLogoFile != null
                                ? FileImage(_companyLogoFile!)
                                : (_networkCompanyLogoUrl != null &&
                                        _networkCompanyLogoUrl!.isNotEmpty
                                    ? NetworkImage(_networkCompanyLogoUrl!)
                                    : null) as ImageProvider?,
                            child: (_companyLogoFile == null &&
                                    (_networkCompanyLogoUrl == null ||
                                        _networkCompanyLogoUrl!.isEmpty))
                                ? Icon(Icons.storefront, size: 60, color: Colors.grey.shade400)
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
                                child: Icon(Icons.edit, color: Colors.white, size: 20),
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
                      validator: (v) => v!.isEmpty ? 'Please enter your business name' : null,
                    ),
                    const SizedBox(height: 20),
                    const Text('Service Categories',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ..._categories.map((category) {
                      return CheckboxListTile(
                        title: Text(category),
                        value: _selectedCategories.contains(category),
                        onChanged: (bool? isChecked) {
                          setState(() {
                            if (isChecked == true) {
                              _selectedCategories.add(category);
                            } else {
                              _selectedCategories.remove(category);
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                      );
                    }),
                    if (_selectedCategories.isEmpty && !_isSaving)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Please select at least one category.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location (e.g., Kochi)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Please enter your location' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Full Address',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'About Your Business',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                      validator: (v) => v!.isEmpty ? 'Please enter a description' : null,
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Your Services',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ElevatedButton.icon(
                          onPressed: _addService,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A11CB),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Service'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_services.isEmpty)
                      const Center(
                        child: Text(
                          'Click "Add Service" to list what you offer.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ..._services.asMap().entries.map((entry) {
                      int index = entry.key;
                      Map<String, dynamic> service = entry.value;
                      return ServiceForm(
                        key: _serviceFormKeys[index],
                        service: service,
                        categories: _categories,
                        subcategoriesMap: _subcategories,
                        onImagePick: (List<File> images) {
                          setState(() {
                            service['image_files'] = images;
                          });
                        },
                        onTitleChanged: (String title) => service['title'] = title,
                        onDescriptionChanged: (String desc) => service['description'] = desc,
                        onPriceChanged: (String price) => service['price'] = price,
                        onCategoryChanged: (String? category) {
                          setState(() {
                            service['category'] = category;
                            service['subcategory'] = null; // reset subcategory
                          });
                        },
                        onSubcategoryChanged: (String? subcat) {
                          setState(() => service['subcategory'] = subcat);
                        },
                        onRemove: () => _removeService(index),
                        onNetworkImageRemove: (String imageUrl) {
                          setState(() {
                            List<String> currentUrls = List<String>.from(service['image_urls']);
                            currentUrls.remove(imageUrl);
                            service['image_urls'] = currentUrls;
                          });
                        },
                        onFileImageRemove: (File file) {
                          setState(() {
                            List<File> currentFiles = List<File>.from(service['image_files']);
                            currentFiles.remove(file);
                            service['image_files'] = currentFiles;
                          });
                        },
                      );
                    }),
                    const SizedBox(height: 30),
                    if (_errorMessage != null)
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF6A11CB),
                        foregroundColor: Colors.white,
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Submit for Review', style: TextStyle(fontSize: 16)),
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
  final VoidCallback onRemove;
  final List<String> categories;
  final Map<String, List<String>> subcategoriesMap;
  final ValueChanged<List<File>> onImagePick;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<String> onPriceChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onSubcategoryChanged;
  final ValueChanged<String> onNetworkImageRemove;
  final ValueChanged<File> onFileImageRemove;

  const ServiceForm({
    required Key key,
    required this.service,
    required this.onRemove,
    required this.categories,
    required this.subcategoriesMap,
    required this.onImagePick,
    required this.onTitleChanged,
    required this.onDescriptionChanged,
    required this.onPriceChanged,
    required this.onCategoryChanged,
    required this.onSubcategoryChanged,
    required this.onNetworkImageRemove,
    required this.onFileImageRemove,
  }) : super(key: key);

  @override
  State<ServiceForm> createState() => _ServiceFormState();
}

class _ServiceFormState extends State<ServiceForm> {
  final ImagePicker _picker = ImagePicker();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  String? _selectedCategory;
  String? _selectedSubcategory;

  List<File> _currentImageFiles = [];
  List<String> _currentNetworkImageUrls = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.service['title']);
    _descriptionController = TextEditingController(text: widget.service['description']);
    _priceController = TextEditingController(text: widget.service['price'].toString());
    _selectedCategory = widget.service['category'];
    _selectedSubcategory = widget.service['subcategory'];

    _currentImageFiles = List<File>.from(widget.service['image_files'] ?? []);
    _currentNetworkImageUrls = List<String>.from(widget.service['image_urls'] ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _currentImageFiles.addAll(pickedFiles.map((e) => File(e.path)));
        widget.onImagePick(_currentImageFiles);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> subcategories = _selectedCategory != null
        ? widget.subcategoriesMap[_selectedCategory!] ?? []
        : [];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
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
                  icon: const Icon(Icons.close, color: Colors.redAccent),
                  onPressed: widget.onRemove,
                ),
              ),
              const Text("Service Images", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._currentImageFiles.map<Widget>((file) {
                    return Stack(
                      children: [
                        Image.file(file, width: 100, height: 100, fit: BoxFit.cover),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentImageFiles.remove(file);
                                widget.onFileImageRemove(file);
                              });
                            },
                            child: const Icon(Icons.close, color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  }),
                  ..._currentNetworkImageUrls.map<Widget>((url) {
                    return Stack(
                      children: [
                        Image.network(url, width: 100, height: 100, fit: BoxFit.cover),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentNetworkImageUrls.remove(url);
                                widget.onNetworkImageRemove(url);
                              });
                            },
                            child: const Icon(Icons.close, color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  }),
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[300],
                      child: const Icon(Icons.add_a_photo),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                value: _selectedCategory,
                items: widget.categories
                    .map<DropdownMenuItem<String>>(
                        (c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategory = val;
                    _selectedSubcategory = null;
                  });
                  widget.onCategoryChanged(val);
                  widget.onSubcategoryChanged(null);
                },
                validator: (v) => v == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Subcategory', border: OutlineInputBorder()),
                value: _selectedSubcategory,
                items: subcategories
                    .map<DropdownMenuItem<String>>((sub) => DropdownMenuItem<String>(
                          value: sub,
                          child: Text(sub),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() => _selectedSubcategory = val);
                  widget.onSubcategoryChanged(val);
                },
                validator: (v) => v == null ? 'Please select a subcategory' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Service Title'),
                onChanged: widget.onTitleChanged,
                validator: (v) => v!.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                onChanged: widget.onDescriptionChanged,
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Starting Price'),
                keyboardType: TextInputType.number,
                onChanged: widget.onPriceChanged,
                validator: (v) => v!.isEmpty ? 'Price is required' : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
