import 'package:appwrite/appwrite.dart';
import 'package:dukkan/core/observability.dart';
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
    } on Exception catch (e, st) {
      if (!mounted) return;
      await AppLogger.captureException(e,
          stackTrace: st, area: 'auth.send_verification');
      showAlert(
          title: 'فشل إرسال رمز التحقق',
          text: UserSafeMessages.verificationFailed);
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
        showAlert(title: 'رمز التحقق مطلوب', text: 'يرجى إدخال رمز التحقق');
        return;
      }

      final verified = await appwrite.confirmVerification(
        userId: widget.userId,
        secret: enteredCode,
      );

      if (!verified) {
        if (!mounted) return;
        showAlert(
          title: 'رمز التحقق غير صحيح',
          text: 'يرجى إدخال الرمز الصحيح المرسل إلى بريدك الإلكتروني',
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
          content: Text('تم إنشاء الحساب بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MyApp()),
        (route) => false,
      );
    } on AppwriteException catch (e, st) {
      if (!mounted) return;
      await AppLogger.captureException(e,
          stackTrace: st, area: 'auth.verify_email');
      showAlert(title: 'فشل التحقق', text: UserSafeMessages.verificationFailed);
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
              child: const Text('موافق'),
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
        title: const Text('تأكيد البريد الإلكتروني'),
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
                    'تم إرسال رمز التحقق',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'يرجى مراجعة بريدك الإلكتروني ${widget.email} للحصول على رمز التحقق',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'أدخل رمز التحقق',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.security),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : verifyAndCreateAccount,
                    icon: const Icon(Icons.check_circle),
                    label: Text(
                        _isLoading ? 'جار التحقق...' : 'تحقق وأنشئ الحساب'),
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
