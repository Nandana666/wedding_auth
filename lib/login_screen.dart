import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _isLoggingIn = false;
  String? _errorMessage;

  Future<String?> _getRole(String uid) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists) return 'user';

    final vendorDoc =
        await FirebaseFirestore.instance.collection('vendors').doc(uid).get();
    if (vendorDoc.exists) return 'vendor';

    final adminDoc =
        await FirebaseFirestore.instance.collection('Admin').doc(uid).get();
    if (adminDoc.exists) return 'admin';

    return null;
  }

  Future<void> _login() async {
    if (_isLoggingIn) return;
    setState(() {
      _isLoggingIn = true;
      _errorMessage = null;
    });

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      final uid = cred.user!.uid;
      final role = await _getRole(uid);

      if (!mounted) return;

      switch (role) {
        case 'user':
          Navigator.pushReplacementNamed(context, '/userHome');
          break;
        case 'vendor':
          Navigator.pushReplacementNamed(context, '/vendorHome');
          break;
        case 'admin':
          Navigator.pushReplacementNamed(context, '/adminHome');
          break;
        default:
          setState(() => _errorMessage = 'Role not found for this account.');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email')),
            TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoggingIn ? null : _login,
              child: _isLoggingIn
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Login'),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/signup'),
              child: const Text('Create an account'),
            ),
          ],
        ),
      ),
    );
  }
}
