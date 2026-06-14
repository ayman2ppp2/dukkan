import 'package:dukkan/providers/onlineProvider.dart';
import 'package:flutter/material.dart';
// import 'package:appwrite_app/appwrite/auth_api.dart';
import 'package:provider/provider.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({Key? key}) : super(key: key);

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late String? email, username;
  TextEditingController bioTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final AuthAPI appwrite = context.read<AuthAPI>();
    email = appwrite.email;
    username = appwrite.username;
    appwrite.getUserPreferences().then((value) {
      if (value.data.isNotEmpty) {
        setState(() {
          bioTextController.text = value.data['bio'];
        });
      }
    });
  }

  signOut() {
    final AuthAPI appwrite = context.read<AuthAPI>();
    appwrite.signOut();
  }

  savePreferences() {
    final AuthAPI appwrite = context.read<AuthAPI>();
    appwrite.updatePreferences(bio: bioTextController.text);
    const snackbar = SnackBar(content: Text('تم تحديث الإعدادات'));
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('حسابي'),
          actions: [
            IconButton(
              tooltip: 'تسجيل الخروج',
              icon: const Icon(Icons.logout),
              onPressed: () {
                signOut();
              },
            ),
          ],
        ),
        body: Center(
          child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('مرحباً بعودتك $username',
                      style: Theme.of(context).textTheme.headlineSmall),
                  Text('$email'),
                  const SizedBox(height: 40),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        TextField(
                          controller: bioTextController,
                          decoration: const InputDecoration(
                            labelText: 'نبذة عنك',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => savePreferences(),
                          child: const Text('حفظ الإعدادات'),
                        ),
                      ]),
                    ),
                  )
                ],
              )),
        ));
  }
}
