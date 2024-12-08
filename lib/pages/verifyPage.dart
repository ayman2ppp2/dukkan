import 'package:appwrite/appwrite.dart';
import 'package:dukkan/main.dart';
import 'package:dukkan/providers/onlineProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VerficationPage extends StatefulWidget {
  final int code;
  final String email;
  final String password;
  final String name;
  const VerficationPage({
    super.key,
    required this.code,
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  State<VerficationPage> createState() => _VerficationPageState();
}

class _VerficationPageState extends State<VerficationPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Show the verification code in debug mode
    print('Verification code: ${widget.code}');
  }

  createAccount() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final AuthAPI appwrite = context.read<AuthAPI>();
      await appwrite.createUser(
        email: widget.email,
        password: widget.password,
        name: widget.name,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to the app's main screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MyApp()),
        (route) => false,
      );
    } on AppwriteException catch (e) {
      if (!mounted) return;
      showAlert(title: 'Account creation failed', text: e.message.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  showAlert({required String title, required String text}) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(text),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.email_outlined,
                    size: 64,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Verification Code Sent',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check your email ${widget.email} for the verification code',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Verification Code',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.security),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      final enteredCode = int.tryParse(_codeController.text) ?? 0;
                      if (enteredCode == widget.code) {
                        createAccount();
                      } else {
                        showAlert(
                          title: 'Invalid Code',
                          text: 'Please enter the correct verification code',
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Verify and Create Account'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
