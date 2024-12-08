import 'package:appwrite/appwrite.dart';
import 'package:dukkan/pages/verifyPage.dart';
import 'package:dukkan/providers/onlineProvider.dart';
// import 'package:appwrite_app/appwrite/auth_api.dart';
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
          title: 'Invalid Email', text: 'Please enter a valid email address');
      return false;
    }
    if (passwordTextController.text.isEmpty ||
        passwordTextController.text.length < 8) {
      showAlert(
          title: 'Invalid Password',
          text: 'Password must be at least 8 characters long');
      return false;
    }
    if (nameTextController.text.isEmpty) {
      showAlert(title: 'Invalid Name', text: 'Please enter your name');
      return false;
    }
    if (phoneTextController.text.isEmpty ||
        phoneTextController.text.length < 9) {
      showAlert(
          title: 'Invalid Phone', text: 'Please enter a valid phone number');
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
      final code =
          await appwrite.verifyUser(email: emailTextController.text.trim());

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider.value(
            value: appwrite,
            child: VerficationPage(
              code: code,
              email: emailTextController.text,
              password: passwordTextController.text,
              name: nameTextController.text,
            ),
          ),
        ),
      );
    } on Exception catch (e) {
      showAlert(title: 'Verification failed', text: e.toString());
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
                  child: const Text('Ok'))
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create your account'),
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
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameTextController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
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
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordTextController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: createAccount,
                    icon: const Icon(Icons.app_registration),
                    label: const Text('Sign up'),
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
