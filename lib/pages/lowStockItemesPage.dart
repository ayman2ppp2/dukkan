// /e:/flutter apps/dukkan/lib/pages/lowStockItemesPage.dart
// Adjust the Lists import path / method names if your provider differs.
import 'package:dukkan/providers/list.dart';
import 'package:dukkan/util/models/Product.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// adjust path if needed

class LowStockItemsPage extends StatelessWidget {
  const LowStockItemsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lists = Provider.of<Lists>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('عناصر منخفضة المخزون')),
      body: FutureBuilder<List<Product>>(
        // Replace `fetchProducts()` with the actual method on your Lists provider
        future: lists.getLowStockItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final products = snapshot.data ?? <Product>[];

          if (products.isEmpty) {
            return const Center(child: Text('No low stock items'));
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, i) {
              final item = products[i];
              return ListTile(
                title: Text(item.name!),
                subtitle: Text(item.count.toString()),
                // optional: add trailing, onTap, etc.
              );
            },
          );
        },
      ),
    );
  }
}
