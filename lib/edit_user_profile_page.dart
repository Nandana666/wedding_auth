import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditUserProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditUserProfilePage({super.key, required this.userData});

  @override
  State<EditUserProfilePage> createState() => _EditUserProfilePageState();
}

class _EditUserProfilePageState extends State<EditUserProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _locationController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _reviewController;

  double _rating = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name']);
    _emailController = TextEditingController(text: widget.userData['email']);
    _locationController = TextEditingController(text: widget.userData['location']);
    _phoneController = TextEditingController(text: widget.userData['phone']);
    _addressController = TextEditingController(text: widget.userData['address']);
    _reviewController = TextEditingController(text: widget.userData['review'] ?? '');
    _rating = (widget.userData['rating'] ?? 0).toDouble();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      final user = FirebaseAuth.instance.currentUser!;
      try {
        // Update Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'location': _locationController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'review': _reviewController.text.trim(),
          'rating': _rating,
        });

        // Update Auth email if changed
        if (_emailController.text.trim() != user.email) {
          await user.verifyBeforeUpdateEmail(_emailController.text.trim());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Verification email sent to update your email. Please verify to complete the change.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }

        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Details saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save details: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return IconButton(
          icon: Icon(
            Icons.star,
            color: starIndex <= _rating ? Colors.amber : Colors.grey,
            size: 32,
          ),
          onPressed: () {
            setState(() {
              _rating = starIndex.toDouble();
            });
          },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Your Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 20),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter your email';
                  if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter your phone number';
                  if (!RegExp(r'^\d{10}$').hasMatch(v)) {
                    return 'Please enter a valid 10-digit phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location (e.g., Kochi)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Rating
              const Text("Your Rating:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              _buildStarRating(),
              const SizedBox(height: 20),

              // Review
              TextFormField(
                controller: _reviewController,
                decoration: const InputDecoration(
                  labelText: 'Write a Review',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 30),

              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
