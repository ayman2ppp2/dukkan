import 'package:dukkan/core/router/auth_gate.dart';
import 'package:dukkan/core/router/route_args.dart';
import 'package:dukkan/core/router/splash_screen.dart';
import 'package:dukkan/pages/auth/payment_verification_page.dart';
import 'package:dukkan/pages/auth/register_page.dart';
import 'package:dukkan/pages/auth/verify_page.dart';
import 'package:dukkan/pages/expenses/spendings_page.dart';
import 'package:dukkan/pages/expenses/spending_page.dart';
import 'package:dukkan/pages/inbound/inbound_receipt_page.dart';
import 'package:dukkan/pages/inventory/inventory_page.dart';
import 'package:dukkan/pages/inventory/low_stock_page.dart';
import 'package:dukkan/pages/loans/account_statement_page.dart';
import 'package:dukkan/pages/loans/loan_detail_page.dart';
import 'package:dukkan/pages/loans/loans_page.dart';
import 'package:dukkan/pages/logs/logs_page.dart';
import 'package:dukkan/pages/settings/settings_page.dart';
import 'package:dukkan/models/Loaner.dart';
import 'package:dukkan/widgets/confirmation_page.dart';
import 'package:go_router/go_router.dart';

/// Central route table for the app.
///
/// Providers are registered above the router in `main.dart`, so every route
/// can `context.read`/`context.watch` them directly — the old
/// `ChangeNotifierProvider.value` re-wrap idiom on pushed routes is gone.
class AppRouter {
  static GoRouter create({String initialLocation = '/splash'}) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const AuthGate(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: '/verify',
          builder: (context, state) {
            final args = state.extra as VerifyPageArgs;
            return VerficationPage(
              userId: args.userId,
              email: args.email,
              password: args.password,
              name: args.name,
            );
          },
        ),
        GoRoute(
          path: '/payment-verification',
          builder: (context, state) => const PaymentVerificationPage(),
        ),
        GoRoute(
          path: '/logs',
          builder: (context, state) => Logs(),
        ),
        GoRoute(
          path: '/inventory',
          builder: (context, state) => const InvPage(),
        ),
        GoRoute(
          path: '/inventory/low-stock',
          builder: (context, state) => const LowStockItemsPage(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: '/loans',
          builder: (context, state) => const Loans(),
        ),
        GoRoute(
          path: '/loans/:id',
          builder: (context, state) => Loan(loaner: state.extra as Loaner),
        ),
        GoRoute(
          path: '/expenses',
          builder: (context, state) => const Spendings(),
        ),
        GoRoute(
          path: '/expenses/:id',
          builder: (context, state) => Spending(
            id: int.parse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/inbound',
          builder: (context, state) => inboundReceipt(),
        ),
        GoRoute(
          path: '/bank-statement',
          builder: (context, state) {
            final loaner = state.extra as Loaner;
            return BankStatementPage(
              accountNumber: loaner.ID.toString(),
              customerName: loaner.name.toString(),
              loaner: loaner,
            );
          },
        ),
        GoRoute(
          path: '/confirmation',
          builder: (context, state) {
            final args = state.extra as ConfirmationArgs;
            return ConfirmationPage(
              paied: args.paied,
              date: args.date,
              name: args.name,
              remaining: args.remaining,
              clearField: args.clearField,
              type: args.type,
            );
          },
        ),
      ],
    );
  }
}
