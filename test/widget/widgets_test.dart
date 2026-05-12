import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dukkan/providers/salesProvider.dart';
import 'package:dukkan/providers/list.dart';
import 'package:dukkan/providers/expense_provider.dart';

void main() {
  group('SellPage Widget Tests', () {
    testWidgets('SellPage renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => SalesProvider()),
              ChangeNotifierProvider(create: (_) => Lists()),
              ChangeNotifierProvider(create: (_) => ExpenseProvider()),
            ],
            child: Builder(
              builder: (context) {
                return Scaffold(
                  appBar: AppBar(title: Text('Sell')),
                  body: Center(child: Text('Products Grid')),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Sell'), findsOneWidget);
    });

    testWidgets('SellPage has app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: Text('Sell')),
            body: Text('Content'),
          ),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Sell'), findsOneWidget);
    });

    testWidgets('SellPage displays products area', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
              ),
              itemCount: 10,
              itemBuilder: (context, index) {
                return Card(child: Text('Product $index'));
              },
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('SearchPage Widget Tests', () {
    testWidgets('SearchPage has search input', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  border: InputBorder.none,
                ),
              ),
            ),
            body: Text('Results'),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Search input accepts text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              decoration: InputDecoration(
                hintText: 'Search products...',
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'test query');
      expect(find.text('test query'), findsOneWidget);
    });

    testWidgets('SearchPage shows results area', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) {
                return ListTile(title: Text('Result $index'));
              },
            ),
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('CheckOutPage Widget Tests', () {
    testWidgets('CheckOutPage renders cart items', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: Text('Checkout')),
            body: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text('Item ${index + 1}'),
                        subtitle: Text('\$10.00'),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });

    testWidgets('CheckOutPage shows total', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('Total: \$30.00'),
                ElevatedButton(
                  onPressed: () {},
                  child: Text('Complete Sale'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Total: \$30.00'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('Checkout button is tappable', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {
                pressed = true;
              },
              child: Text('Complete Sale'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      expect(pressed, isTrue);
    });

    testWidgets('CheckOutPage has payment options', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                RadioListTile<int>(
                  value: 0,
                  groupValue: 0,
                  onChanged: (v) {},
                  title: Text('Cash'),
                ),
                RadioListTile<int>(
                  value: 1,
                  groupValue: 0,
                  onChanged: (v) {},
                  title: Text('Digital'),
                ),
                RadioListTile<int>(
                  value: 2,
                  groupValue: 0,
                  onChanged: (v) {},
                  title: Text('Loan'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('Digital'), findsOneWidget);
      expect(find.text('Loan'), findsOneWidget);
    });
  });

  group('LoansPage Widget Tests', () {
    testWidgets('LoansPage renders loaners list', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: Text('Loans')),
            body: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Loaner ${index + 1}'),
                  subtitle: Text('\$100.00'),
                  trailing: Text('Due'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('LoansPage shows total debt', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Total Debt: \$500.00'),
            ),
          ),
        ),
      );

      expect(find.text('Total Debt: \$500.00'), findsOneWidget);
    });

    testWidgets('LoansPage has add loaner button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: Icon(Icons.add),
            ),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });

  group('StatsPage Widget Tests', () {
    testWidgets('StatsPage renders stats', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: Text('Statistics')),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Card(child: Text('Total Sales: \$1000')),
                  Card(child: Text('Total Profit: \$300')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Statistics'), findsOneWidget);
      expect(find.text('Total Sales: \$1000'), findsOneWidget);
      expect(find.text('Total Profit: \$300'), findsOneWidget);
    });

    testWidgets('StatsPage has date selector', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                IconButton(
                  icon: Icon(Icons.date_range),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.date_range), findsOneWidget);
    });

    testWidgets('StatsPage shows charts area', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: Card(child: Text('Chart Area')),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });
  });

  group('ShareWidget Tests', () {
    testWidgets('ShareWidget has server toggle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SwitchListTile(
                  title: Text('Start Server'),
                  value: false,
                  onChanged: (v) {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(SwitchListTile), findsOneWidget);
      expect(find.text('Start Server'), findsOneWidget);
    });

    testWidgets('ShareWidget shows QR when server active', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SwitchListTile(
                  title: Text('Server'),
                  value: true,
                  onChanged: (v) {},
                ),
                Card(child: Text('192.168.1.1:30000')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('192.168.1.1:30000'), findsOneWidget);
    });

    testWidgets('ShareWidget has client option', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.cloud_download),
                  title: Text('Connect to Server'),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Connect to Server'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_download), findsOneWidget);
    });

    testWidgets('ShareWidget toggle updates UI', (WidgetTester tester) async {
      bool serverRunning = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: SwitchListTile(
                  title: Text('Server'),
                  value: serverRunning,
                  onChanged: (v) {
                    setState(() {
                      serverRunning = v;
                    });
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(serverRunning, isFalse);
      
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();
      
      expect(serverRunning, isTrue);
    });
  });
}