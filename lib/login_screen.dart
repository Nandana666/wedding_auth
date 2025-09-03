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
  bool _isPasswordVisible = false;

  Future<String?> _getRole(String uid) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists) return 'user';

    final adminDoc =
        await FirebaseFirestore.instance.collection('Admin').doc(uid).get();
    if (adminDoc.exists) return 'admin';

    final vendorDoc =
        await FirebaseFirestore.instance.collection('vendors').doc(uid).get();
    if (vendorDoc.exists) {
      final status = (vendorDoc.data() as Map<String, dynamic>)['status'];
      switch (status) {
        case 'approved':
          return 'vendor_approved';
        case 'incomplete':
        case 'pending_approval':
          return 'vendor_pending';
        case 'declined':
          return 'vendor_declined';
      }
    }

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
          Navigator.pushReplacementNamed(context, '/home');
          break;
        case 'vendor_approved':
        case 'vendor_pending':
          Navigator.pushReplacementNamed(context, '/vendorDashboard');
          break;
        case 'admin':
          Navigator.pushReplacementNamed(context, '/adminHome');
          break;
        case 'vendor_declined':
          setState(
            () => _errorMessage = 'Your vendor application was declined.',
          );
          await _auth.signOut();
          break;
        default:
          setState(() => _errorMessage = 'Account not found or access denied.');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_email.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email to reset password.';
      });
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _email.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent. Check your inbox.'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top gradient background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.3,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFDEBFF), Color(0xFFE1D5FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // White rounded container
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.0),
                  topRight: Radius.circular(40.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Log in to your account to continue.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    _buildTextField(
                      controller: _email,
                      hintText: 'Email Address',
                    ),
                    const SizedBox(height: 20),
                    _buildPasswordField(),
                    const SizedBox(height: 10),
                    _buildForgotPasswordLink(), // 🔹 Added here
                    const SizedBox(height: 20),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 20),
                    _buildLoginButton(),
                    const SizedBox(height: 20),
                    _buildSignupLink(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _password,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        hintText: 'Password',
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
      ),
    );
  }

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _resetPassword,
        child: const Text(
          'Forgot Password?',
          style: TextStyle(
            color: Color(0xFFC0A0FF),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFA0D5), Color(0xFFC0A0FF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withAlpha(77),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoggingIn ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: _isLoggingIn
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : const Text(
                'Log In',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildSignupLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: TextStyle(color: Colors.grey.shade600),
        ),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/signup'),
          child: const Text(
            'Sign up',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFC0A0FF),
            ),
          ),
        ),
      ],
    );
  }
}
