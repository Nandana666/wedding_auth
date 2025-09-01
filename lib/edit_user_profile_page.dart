// lib/edit_user_profile_page.dart

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
  late TextEditingController _dateController;
  late TextEditingController _locationController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name']);
    _dateController = TextEditingController(
      text: widget.userData['weddingDate'],
    );
    _locationController = TextEditingController(
      text: widget.userData['weddingLocation'],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      final user = FirebaseAuth.instance.currentUser!;
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'name': _nameController.text.trim(),
              'weddingDate': _dateController.text.trim(),
              'weddingLocation': _locationController.text.trim(),
            });
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
            const SnackBar(
              content: Text('Failed to save details.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
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
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Wedding Date',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_month),
                    onPressed: _selectDate,
                  ),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Wedding Location (e.g., Kochi)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),
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
