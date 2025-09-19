// lib/fake_payment_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

// Enum to manage the different stages of our fake payment flow
enum PaymentStage { details, pin, processing, success }

class FakePaymentPage extends StatefulWidget {
  final double amount;

  const FakePaymentPage({super.key, required this.amount});

  @override
  State<FakePaymentPage> createState() => _FakePaymentPageState();
}

class _FakePaymentPageState extends State<FakePaymentPage>
    with SingleTickerProviderStateMixin {
  PaymentStage _currentStage = PaymentStage.details;
  late AnimationController _lottieController;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);

    // This listener will trigger when the success animation finishes
    _lottieController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Pop the page and return 'true' to indicate success
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  void _advanceStage(PaymentStage nextStage) {
    setState(() {
      _currentStage = nextStage;
    });

    // If we are moving to the processing stage, simulate a delay
    if (nextStage == PaymentStage.processing) {
      Future.delayed(const Duration(seconds: 2), () {
        _advanceStage(PaymentStage.success);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Complete Payment'),
        backgroundColor: const Color(0xFF6A11CB),
      ),
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildUIForStage(),
        ),
      ),
    );
  }

  Widget _buildUIForStage() {
    switch (_currentStage) {
      case PaymentStage.details:
        return _buildDetailsView();
      case PaymentStage.pin:
        return _buildPinView();
      case PaymentStage.processing:
        return _buildProcessingView();
      case PaymentStage.success:
        return _buildSuccessView();
    }
  }

  Widget _buildDetailsView() {
    return Padding(
      key: const ValueKey('details'),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Paying to',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Wedding Planner Inc.',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 40),
                  const Text('Amount', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    '₹${widget.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF2575FC),
              ),
              onPressed: () => _advanceStage(PaymentStage.pin),
              child: const Text('Proceed to Pay'),
            ),
          ),
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
          const Text(
            'Enter UPI PIN',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const TextField(
            obscureText: true,
            maxLength: 6,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, letterSpacing: 12),
            decoration: InputDecoration(
              counterText: '',
              border: OutlineInputBorder(),
              hintText: '● ● ● ●',
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              backgroundColor: Colors.green,
            ),
            onPressed: () => _advanceStage(PaymentStage.processing),
            icon: const Icon(Icons.check_circle),
            label: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingView() {
    return const Column(
      key: ValueKey('processing'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 20),
        Text('Processing Payment...', style: TextStyle(fontSize: 18)),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Lottie.asset(
      key: const ValueKey('success'),
      'assets/success_animation.json',
      controller: _lottieController,
      onLoaded: (composition) {
        // Configure the animation controller and play it
        _lottieController
          ..duration = composition.duration
          ..forward();
      },
    );
  }
}
