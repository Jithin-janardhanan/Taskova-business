// // This is a placeholder for the OTP Verification screen
// // You would implement this in a separate file
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:taskova_shopkeeper/Model/api_config.dart';
import 'package:taskova_shopkeeper/auth/reset_password.dart';


class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isSuccess = false;

  Future<void> _sendForgotPasswordEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final Uri url = Uri.parse(ApiConfig.forgotPasswordUrl);
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode({"email": _emailController.text.trim()});

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        setState(() {
          _isSuccess = true;
          _errorMessage = '';
        });
      } else {
        final responseData = json.decode(response.body);
        setState(() {
          _errorMessage = responseData['detail'] ?? 'Failed to send reset code.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              Icon(Icons.lock_reset, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 20),
              const Text(
                'Reset Your Password',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                _isSuccess
                    ? 'A verification code has been sent to your email.'
                    : 'Enter your email to receive a reset code.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 30),
              
              if (!_isSuccess) _buildEmailField(),
              const SizedBox(height: 20),
              if (_errorMessage.isNotEmpty) _buildErrorMessage(),

              _isSuccess
                  ? _buildContinueButton(context)
                  : _buildSubmitButton(),

              const SizedBox(height: 20),
              _buildBackToLogin(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: 'Email',
        hintText: 'Enter your email',
        prefixIcon: Icon(Icons.email_outlined),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Invalid email format';
        }
        return null;
      },
    );
  }

  Widget _buildErrorMessage() {
    return Text(
      _errorMessage,
      style: const TextStyle(color: Colors.red, fontSize: 14),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _sendForgotPasswordEmail,
      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text('Send Verification Code'),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerificationScreen(email: _emailController.text.trim()),
          ),
        );
      },
      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
      child: const Text('Continue to Verification'),
    );
  }

  Widget _buildBackToLogin() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('Back to Login'),
    );
  }
}