import 'package:dukkan/pages/onboarding/landing_page.dart';
import 'package:dukkan/providers/sales_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../pages/home/home_page.dart';
import '../../pages/auth/login_page.dart';

/// Decides which top-level page to show based on auth state and onboarding
/// progress. Replaces the inline gate that lived inside `main.dart`.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthAPI>();
    if (auth.status == AuthStatus.uninitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    if (auth.status == AuthStatus.authenticated) {
      return context.read<SalesProvider>().getWeightPrececsion() == null
          ? const LandingPage()
          : const HomePage();
    }
    return const LoginPage();
  }
}
