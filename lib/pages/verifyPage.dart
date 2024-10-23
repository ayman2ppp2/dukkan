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
  createAccount() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  CircularProgressIndicator(),
                ]),
          );
        });
    try {
      final AuthAPI appwrite = context.read<AuthAPI>();
      await appwrite.createUser(
        email: widget.email,
        password: widget.password,
        name: widget.name,
      );

      // .then((value) => value.emailVerification?null:appwrite.account.createVerification(url: url));

      Navigator.pop(context);
      const snackbar = SnackBar(content: Text('Account created!'));
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyApp(),
          ));
    } on AppwriteException catch (e) {
      Navigator.pop(context);
      showAlert(title: 'Account creation failed', text: e.message.toString());
    }
  }

  showAlert({required String title, required String text}) {
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
    TextEditingController codeCon = TextEditingController();
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Enter the code'),
          SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Center(
              child: TextField(
                controller: codeCon,
                decoration: const InputDecoration(
                  labelText: 'code',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              print(widget.code);
              if (widget.code == (int.tryParse(codeCon.text) ?? 0)) {
                createAccount();
              }
            },
            icon: const Icon(Icons.app_registration),
            label: const Text('Sign up'),
          ),
        ],
      ),
    );
  }
}
