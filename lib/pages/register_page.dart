import 'package:appwrite/appwrite.dart';
import 'package:dukkan/core/observability.dart';
import 'package:dukkan/pages/verifyPage.dart';
import 'package:dukkan/providers/onlineProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailTextController = TextEditingController();
  final passwordTextController = TextEditingController();
  final phoneTextController = TextEditingController();
  final nameTextController = TextEditingController();
  bool _isLoading = false;

  bool _validateInputs() {
    if (emailTextController.text.isEmpty ||
        !emailTextController.text.contains('@')) {
      showAlert(
          title: 'البريد الإلكتروني غير صحيح',
          text: 'يرجى إدخال بريد إلكتروني صحيح');
      return false;
    }
    if (passwordTextController.text.isEmpty ||
        passwordTextController.text.length < 8) {
      showAlert(
          title: 'كلمة المرور غير صحيحة',
          text: 'يجب أن تكون كلمة المرور 8 أحرف على الأقل');
      return false;
    }
    if (nameTextController.text.isEmpty) {
      showAlert(title: 'الاسم مطلوب', text: 'يرجى إدخال الاسم');
      return false;
    }
    if (phoneTextController.text.isEmpty ||
        phoneTextController.text.length < 9) {
      showAlert(title: 'رقم الهاتف غير صحيح', text: 'يرجى إدخال رقم هاتف صحيح');
      return false;
    }
    return true;
  }

  createAccount() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final AuthAPI appwrite = context.read<AuthAPI>();
      final user = await appwrite.createUser(
        email: emailTextController.text.trim(),
        password: passwordTextController.text.trim(),
        name: nameTextController.text.trim(),
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider.value(
            value: appwrite,
            child: VerficationPage(
              userId: user.$id,
              email: emailTextController.text.trim(),
              password: passwordTextController.text.trim(),
              name: nameTextController.text.trim(),
            ),
          ),
        ),
      );
    } on AppwriteException catch (e, st) {
      if (!mounted) return;
      await AppLogger.captureException(e,
          stackTrace: st, area: 'auth.register');
      showAlert(
          title: 'فشل إنشاء الحساب', text: UserSafeMessages.registerFailed);
    } on Exception catch (e, st) {
      if (!mounted) return;
      await AppLogger.captureException(e,
          stackTrace: st, area: 'auth.register');
      showAlert(title: 'فشل التحقق', text: UserSafeMessages.verificationFailed);
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
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('موافق'))
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء حساب'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: emailTextController,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameTextController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneTextController,
                    decoration: const InputDecoration(
                      prefix: Text('+249 '),
                      labelText: 'رقم الهاتف',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordTextController,
                    decoration: const InputDecoration(
                      labelText: 'كلمة المرور',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: createAccount,
                    icon: const Icon(Icons.app_registration),
                    label: const Text('إنشاء الحساب'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
