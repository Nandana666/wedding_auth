// lib/fake_payment_page.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

// Enum to manage the different stages of our fake payment flow
enum PaymentStage {
  paymentMethod,
  details,
  verification,
  pin,
  processing,
  success,
}

enum PaymentMethod { upiId, phoneNumber, qrCode }

class FakePaymentPage extends StatefulWidget {
  final double amount;
  final String merchantName;
  final String merchantUPI;

  const FakePaymentPage({
    super.key,
    required this.amount,
    this.merchantName = 'Wedding Planner Inc.',
    this.merchantUPI = 'merchant@paytm',
  });

  @override
  State<FakePaymentPage> createState() => _FakePaymentPageState();
}

class _FakePaymentPageState extends State<FakePaymentPage>
    with TickerProviderStateMixin {
  PaymentStage _currentStage = PaymentStage.paymentMethod;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.upiId;
  late AnimationController _lottieController;
  late AnimationController _loadingController;

  // Form controllers and validation
  final TextEditingController _upiController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _bankAccountController = TextEditingController();

  // Transaction details
  String _transactionId = '';
  // FIX: These fields are never reassigned, so they can be final.
  final String _selectedBank = 'State Bank of India';
  final String _selectedAccount = '****1234';
  final DateTime _transactionTime = DateTime.now();
  bool _isProcessing = false;

  // Security features
  // FIX: These fields are never reassigned, so they can be final.
  final bool _biometricEnabled = true;
  final int _remainingAttempts = 3;
  // FIX: Removed unused field '_smsOtpSent'.

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Generate transaction ID
    _transactionId = _generateTransactionId();

    // Set up success animation listener
    _lottieController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Show transaction details for 2 seconds before returning
        Future.delayed(const Duration(seconds: 2), () {
          // FIX: Guard against async gaps by checking if the widget is still mounted.
          if (!mounted) return;
          Navigator.of(context).pop(true);
        });
      }
    });
  }

  String _generateTransactionId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(12, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _loadingController.dispose();
    _upiController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    _bankAccountController.dispose();
    super.dispose();
  }

  void _advanceStage(PaymentStage nextStage) {
    setState(() {
      _currentStage = nextStage;
      if (nextStage == PaymentStage.processing) {
        _isProcessing = true;
      }
    });

    // Simulate processing delay with realistic timing
    if (nextStage == PaymentStage.processing) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _advanceStage(PaymentStage.success);
        }
      });
    }
  }

  void _showSecurityAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.security, color: Colors.green),
        title: const Text('Secure Transaction'),
        content: const Text(
          'This transaction is secured with 256-bit SSL encryption and monitored for fraud.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Pay', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF6739b7),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.security),
            onPressed: _showSecurityAlert,
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
              ),
              child: child,
            );
          },
          child: _buildUIForStage(),
        ),
      ),
    );
  }

  Widget _buildUIForStage() {
    switch (_currentStage) {
      case PaymentStage.paymentMethod:
        return _buildPaymentMethodView();
      case PaymentStage.details:
        return _buildDetailsView();
      case PaymentStage.verification:
        return _buildVerificationView();
      case PaymentStage.pin:
        return _buildPinView();
      case PaymentStage.processing:
        return _buildProcessingView();
      case PaymentStage.success:
        return _buildSuccessView();
    }
  }

  Widget _buildPaymentMethodView() {
    return Padding(
      key: const ValueKey('paymentMethod'),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6739b7), Color(0xFF9c27b0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'Pay ${widget.merchantName}',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${widget.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          const Text(
            'Choose payment method',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),

          // Payment method options
          _buildPaymentMethodOption(
            PaymentMethod.upiId,
            'UPI ID',
            'Enter recipient\'s UPI ID',
            Icons.account_balance,
          ),
          const SizedBox(height: 12),
          _buildPaymentMethodOption(
            PaymentMethod.phoneNumber,
            'Phone Number',
            'Enter recipient\'s mobile number',
            Icons.phone,
          ),
          const SizedBox(height: 12),
          _buildPaymentMethodOption(
            PaymentMethod.qrCode,
            'QR Code',
            'Scan merchant\'s QR code',
            Icons.qr_code_scanner,
          ),

          const Spacer(),

          // Continue button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF6739b7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _advanceStage(PaymentStage.details),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOption(
    PaymentMethod method,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Card(
      elevation: _selectedPaymentMethod == method ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _selectedPaymentMethod == method
              ? const Color(0xFF6739b7)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            // FIX: Replaced deprecated withOpacity with withAlpha.
            color: const Color(0xFF6739b7).withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF6739b7)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Radio<PaymentMethod>(
          value: method,
          groupValue: _selectedPaymentMethod,
          onChanged: (PaymentMethod? value) {
            setState(() {
              _selectedPaymentMethod = value!;
            });
          },
        ),
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method;
          });
        },
      ),
    );
  }

  Widget _buildDetailsView() {
    return Padding(
      key: const ValueKey('details'),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Merchant details card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Icon(
                          Icons.store,
                          color: Color(0xFF6739b7),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.merchantName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.merchantUPI,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              color: Colors.green.shade700,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Amount', style: TextStyle(fontSize: 16)),
                      Text(
                        '₹${widget.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6739b7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Payment method input
          if (_selectedPaymentMethod == PaymentMethod.upiId) ...[
            const Text(
              'UPI ID',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _upiController,
              decoration: InputDecoration(
                hintText: 'Enter UPI ID (e.g., user@paytm)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.account_balance_wallet),
              ),
            ),
          ] else if (_selectedPaymentMethod == PaymentMethod.phoneNumber) ...[
            const Text(
              'Mobile Number',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Enter 10-digit mobile number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.phone),
                prefixText: '+91 ',
              ),
            ),
          ] else ...[
            Center(
              child: Column(
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner,
                      size: 100,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Scan QR Code', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Bank account selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.account_balance, color: Color(0xFF6739b7)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedBank,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'A/C: $_selectedAccount',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  TextButton(onPressed: () {}, child: const Text('Change')),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Security info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.lock, color: Colors.green.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Secured by bank-grade encryption',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF6739b7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _advanceStage(PaymentStage.verification),
              child: const Text(
                'Proceed to Pay',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationView() {
    return Padding(
      key: const ValueKey('verification'),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              // FIX: Replaced deprecated withOpacity with withAlpha.
              color: const Color(0xFF6739b7).withAlpha(26),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.security,
              size: 40,
              color: Color(0xFF6739b7),
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'Transaction Verification',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'We need to verify this transaction for your security',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),

          const SizedBox(height: 40),

          // Transaction summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('To:', style: TextStyle(color: Colors.grey)),
                      Text(
                        widget.merchantName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Amount:',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        '₹${widget.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Transaction ID:',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        _transactionId,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Verification options
          if (_biometricEnabled) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF6739b7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _advanceStage(PaymentStage.processing),
                icon: const Icon(Icons.fingerprint),
                label: const Text(
                  'Pay with Fingerprint',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _advanceStage(PaymentStage.pin),
                child: const Text(
                  'Use UPI PIN instead',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF6739b7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _advanceStage(PaymentStage.pin),
                child: const Text(
                  'Enter UPI PIN',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPinView() {
    return Padding(
      key: const ValueKey('pin'),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              // FIX: Replaced deprecated withOpacity with withAlpha.
              color: const Color(0xFF6739b7).withAlpha(26),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(Icons.lock, size: 40, color: Color(0xFF6739b7)),
          ),

          const SizedBox(height: 24),
          const Text(
            'Enter UPI PIN',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your 4 or 6 digit UPI PIN to authorize payment',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),

          const SizedBox(height: 40),

          // PIN Input
          TextField(
            controller: _pinController,
            obscureText: true,
            maxLength: 6,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 12),
            decoration: InputDecoration(
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF6739b7),
                  width: 2,
                ),
              ),
              hintText: '● ● ● ●',
              hintStyle: const TextStyle(letterSpacing: 12),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),

          const SizedBox(height: 16),

          // Attempts remaining
          if (_remainingAttempts < 3) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '$_remainingAttempts attempts remaining',
                    style: TextStyle(color: Colors.orange.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF6739b7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (_pinController.text.length >= 4) {
                  _advanceStage(PaymentStage.processing);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid PIN')),
                  );
                }
              },
              icon: const Icon(Icons.check_circle),
              label: const Text(
                'Pay Now',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 16),

          TextButton(onPressed: () {}, child: const Text('Forgot UPI PIN?')),
        ],
      ),
    );
  }

  Widget _buildProcessingView() {
    return Column(
      key: const ValueKey('processing'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated loading indicator
        SizedBox(
          width: 120,
          height: 120,
          child: CircularProgressIndicator(
            strokeWidth: 6,
            valueColor: const AlwaysStoppedAnimation(Color(0xFF6739b7)),
            backgroundColor: Colors.grey.shade300,
          ),
        ),

        const SizedBox(height: 32),
        const Text(
          'Processing Payment...',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Please wait while we process your transaction',
          style: TextStyle(color: Colors.grey.shade600),
        ),

        const SizedBox(height: 40),

        // Processing steps
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildProcessingStep('Validating payment details', true),
                _buildProcessingStep('Connecting to bank', true),
                _buildProcessingStep('Authorizing transaction', _isProcessing),
                _buildProcessingStep('Completing payment', false),
              ],
            ),
          ),
        ),

        const SizedBox(height: 40),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Do not press back or close the app',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingStep(String title, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.circle,
              size: 16,
              color: isCompleted ? Colors.white : Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isCompleted
                    ? Colors.green.shade700
                    : Colors.grey.shade600,
                fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return SingleChildScrollView(
      key: const ValueKey('success'),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Success animation
          SizedBox(
            width: 200,
            height: 200,
            child: Lottie.asset(
              'assets/success_animation.json',
              controller: _lottieController,
              onLoaded: (composition) {
                _lottieController
                  ..duration = composition.duration
                  ..forward();
              },
            ),
          ),

          const Text(
            'Payment Successful!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${widget.amount.toStringAsFixed(2)} paid successfully',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),

          const SizedBox(height: 32),

          // Transaction receipt
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transaction Receipt',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 24),

                  _buildReceiptRow('To', widget.merchantName),
                  _buildReceiptRow(
                    'Amount',
                    '₹${widget.amount.toStringAsFixed(2)}',
                  ),
                  _buildReceiptRow('Transaction ID', _transactionId),
                  _buildReceiptRow(
                    'Date & Time',
                    '${_transactionTime.day}/${_transactionTime.month}/${_transactionTime.year} '
                        '${_transactionTime.hour.toString().padLeft(2, '0')}:'
                        '${_transactionTime.minute.toString().padLeft(2, '0')}',
                  ),
                  _buildReceiptRow('Payment Method', 'UPI'),
                  _buildReceiptRow('Bank', _selectedBank),

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Transaction completed successfully',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share),
                  label: const Text('Share Receipt'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download),
                  label: const Text('Download'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
