import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PhoneAuthWidget extends StatefulWidget {
  const PhoneAuthWidget({super.key});

  @override
  State<PhoneAuthWidget> createState() => _PhoneAuthWidgetState();
}

class _PhoneAuthWidgetState extends State<PhoneAuthWidget> {
  final _firebaseAuth = FirebaseAuth.instance;
  final _phoneNumberController = TextEditingController();
  final _otpCodeController = TextEditingController();

  var _isVerifyPhoneNumberDoing = false;
  var _isSignInDoing = false;

  String? _verificationId;

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _otpCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("Phone Auth:"),
        const SizedBox(height: 8),
        _phoneNumberInput(context),
        const SizedBox(height: 8),
        _otpCodeInput(context),
      ],
    );
  }

  Widget _phoneNumberInput(BuildContext context) {
    return _input(
      labelText: 'Phone Number',
      controller: _phoneNumberController,
      onPressed: () => _onPhoneNumberSend(context),
    );
  }

  Widget _otpCodeInput(BuildContext context) {
    return _input(
      labelText: 'OTP code',
      controller: _otpCodeController,
      onPressed: () => _onOtpCodeSend(context),
    );
  }

  Widget _input({
    required String labelText,
    required TextEditingController controller,
    required VoidCallback onPressed,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: labelText,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: onPressed,
          child: Text("Send"),
        ),
      ],
    );
  }

  void _onPhoneNumberSend(BuildContext context) async {
    if (_phoneNumberController.text.trim().isEmpty) {
      _snackMessage(context, message: 'Phone number is empty');
      return;
    }

    if (_isVerifyPhoneNumberDoing) {
      _snackMessage(context, message: 'Verify phone number is doing');
      return;
    }

    _verificationId = null;
    _isVerifyPhoneNumberDoing = true;

    log('Phone verification started, phone number: ${_phoneNumberController.text}');

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: _phoneNumberController.text,
        verificationCompleted: (credential) {
          log('Verification completed, credential: $credential');
          _snackMessage(context, message: 'verification completed');
          _signInWithCredential(context, credential: credential);
        },
        verificationFailed: (error) {
          log('Verification failed, error: $error');
          _snackMessage(context, message: 'verification failed');
        },
        codeSent: (verificationId, _) {
          log('Code sent, verificationId: $verificationId');
          _snackMessage(context, message: 'code sent');
          _verificationId = verificationId;
        },
        codeAutoRetrievalTimeout: (_) {
          log('Code auto retrieval timeout');
          _snackMessage(context, message: 'code auto retrieval timeout');
        },
      );
      _isVerifyPhoneNumberDoing = false;
      // ignore: use_build_context_synchronously
      _snackMessage(context, message: 'Phone verification started');
    } catch (error) {
      log('Phone verification error: $error');
      // ignore: use_build_context_synchronously
      _snackMessage(context, message: 'Phone verification failed');
      _isVerifyPhoneNumberDoing = false;
    }
  }

  void _onOtpCodeSend(BuildContext context) {
    if (_verificationId == null) {
      _snackMessage(context, message: 'Phone is not verified');
      return;
    }

    if (_otpCodeController.text.trim().isEmpty) {
      _snackMessage(context, message: 'OTP code is empty');
      return;
    }

    if (_isSignInDoing) {
      _snackMessage(context, message: 'Sign in is doing');
      return;
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: _otpCodeController.text,
    );

    _signInWithCredential(context, credential: credential);
  }

  void _snackMessage(BuildContext context, {required String message}) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _signInWithCredential(BuildContext context, {required PhoneAuthCredential credential}) async {
    if (_isSignInDoing) {
      _snackMessage(context, message: 'Sign in is doing');
      return;
    }

    _isSignInDoing = true;

    try {
      await _firebaseAuth.signInWithCredential(credential);
      // ignore: use_build_context_synchronously
      _snackMessage(context, message: 'Sign in successful');
    } catch (error) {
      // ignore: use_build_context_synchronously
      _snackMessage(context, message: 'Sign in failed');
    }

    _isSignInDoing = false;
  }
}
