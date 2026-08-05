import 'package:flutter/widgets.dart';

/// Arguments for the `/verify` route (email verification after registration).
class VerifyPageArgs {
  const VerifyPageArgs({
    required this.userId,
    required this.email,
    required this.password,
    required this.name,
  });

  final String userId;
  final String email;
  final String password;
  final String name;
}

/// Arguments for the `/confirmation` route. `clearField` lets the confirmation
/// page clear the input on the loan screen below it once the user confirms.
class ConfirmationArgs {
  const ConfirmationArgs({
    required this.paied,
    required this.date,
    required this.name,
    required this.remaining,
    required this.clearField,
    this.type = 'payment',
  });

  final String paied;
  final DateTime date;
  final String name;
  final double remaining;
  final VoidCallback clearField;
  final String type;
}
