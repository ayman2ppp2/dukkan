import 'package:dukkan/providers/inventory_provider.dart';
import 'package:dukkan/util/models/LowStockProduct.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LowStockItemsPage extends StatefulWidget {
  const LowStockItemsPage({Key? key}) : super(key: key);

  @override
  State<LowStockItemsPage> createState() => _LowStockItemsPageState();
}

class _LowStockItemsPageState extends State<LowStockItemsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<LowStockProduct>? _allProducts;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final inventory = context.read<InventoryProvider>();
      final products = await inventory.getLowStockItems();
      setState(() {
        _allProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadProducts();
  }

  Color _getStockColor(double percent) {
    if (percent < 0.10) {
      return Colors.red;
    } else if (percent < 0.25) {
      return Colors.orange;
    }
    return Colors.green;
  }

  String _getStockLabel(double percent) {
    if (percent < 0.10) {
      return 'حرج';
    } else if (percent < 0.25) {
      return 'منخفض';
    }
    return 'طبيعي';
  }

  List<LowStockProduct> _filterProducts() {
    if (_allProducts == null) return [];
    if (_searchQuery.isEmpty) return _allProducts!;
    
    final query = _searchQuery.toLowerCase();
    return _allProducts!.where((item) {
      final name = item.product.name?.toLowerCase() ?? '';
      final barcode = item.product.barcode?.toLowerCase() ?? '';
      return name.contains(query) || barcode.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _filterProducts();

    return Scaffold(
      appBar: AppBar(
        title: const Text('عناصر منخفضة المخزون'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: _buildContent(filteredProducts),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<LowStockProduct> products) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('خطأ: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refresh,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (products.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد عناصر منخفضة المخزون',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, i) {
          final item = products[i];
          final stockColor = _getStockColor(item.percentRemaining);
          final percentText = '${(item.percentRemaining * 100).toStringAsFixed(0)}%';
          final unit = item.product.wholeUnit ?? '';
          
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: stockColor,
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(
                item.product.name ?? 'غير معروف',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'الكمية: ${item.currentStock}$unit',
                        style: TextStyle(color: stockColor, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: stockColor.withAlpha((0.2 * 255).round()),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getStockLabel(item.percentRemaining),
                          style: TextStyle(color: stockColor, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'متبقي: $percentText (المبيع: ${item.soldLast30Days}$unit / 30 يوم)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              trailing: item.product.sellPrice != null
                  ? Text(
                      '${item.product.sellPrice!.toStringAsFixed(2)} ₪',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}