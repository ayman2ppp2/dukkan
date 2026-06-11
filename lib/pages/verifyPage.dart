import 'package:appwrite/appwrite.dart';
import 'package:dukkan/main.dart';
import 'package:dukkan/providers/onlineProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VerficationPage extends StatefulWidget {
  final String userId;
  final String email;
  final String password;
  final String name;
  const VerficationPage({
    super.key,
    required this.userId,
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
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _sendVerification();
  }

  Future<void> _sendVerification() async {
    setState(() => _isLoading = true);
    try {
      final AuthAPI appwrite = context.read<AuthAPI>();
      await appwrite.sendVerification();
      setState(() => _emailSent = true);
    } on Exception catch (e) {
      if (!mounted) return;
      showAlert(title: 'Verification failed', text: e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  verifyAndCreateAccount() async {
    setState(() => _isLoading = true);

    try {
      final AuthAPI appwrite = context.read<AuthAPI>();
      final enteredCode = _codeController.text.trim();

      if (enteredCode.isEmpty) {
        showAlert(title: 'Invalid Code', text: 'Please enter the verification code');
        return;
      }

      final verified = await appwrite.confirmVerification(
        userId: widget.userId,
        secret: enteredCode,
      );

      if (!verified) {
        if (!mounted) return;
        showAlert(
          title: 'Invalid Code',
          text: 'Please enter the correct verification code from your email',
        );
        return;
      }

      await appwrite.createEmailSession(
        email: widget.email,
        password: widget.password,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MyApp()),
        (route) => false,
      );
    } on AppwriteException catch (e) {
      if (!mounted) return;
      showAlert(title: 'Verification failed', text: e.message.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      body: _isLoading && !_emailSent
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
                    onPressed: _isLoading ? null : verifyAndCreateAccount,
                    icon: const Icon(Icons.check_circle),
                    label: Text(_isLoading ? 'Verifying...' : 'Verify and Create Account'),
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
