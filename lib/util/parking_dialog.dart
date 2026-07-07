import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ParkedCartData {
  final String uniqueKey;
  final String name;
  final int productCount;
  final double total;

  const ParkedCartData({
    required this.uniqueKey,
    required this.name,
    required this.productCount,
    required this.total,
  });
}

class ParkingDialog extends StatelessWidget {
  final List<ParkedCartData> parkedCarts;
  final int currentCartCount;
  final double currentCartTotal;
  final bool canPark;

  final VoidCallback onPark;
  final void Function(int index) onRestore;
  final void Function(int index) onDelete;
  final VoidCallback? onDismiss;

  const ParkingDialog({
    super.key,
    required this.parkedCarts,
    required this.currentCartCount,
    required this.currentCartTotal,
    required this.canPark,
    required this.onPark,
    required this.onRestore,
    required this.onDelete,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildCurrentCartSection(),
              const SizedBox(height: 16),
              _buildSectionDivider(),
              const SizedBox(height: 16),
              _buildParkedCartsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.pause_circle_outline, size: 22, color: Colors.brown[700]),
        const SizedBox(width: 10),
        Text(
          'الفواتير المعلقة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.brown[800],
          ),
        ),
        const Spacer(),
        if (onDismiss != null)
          GestureDetector(
            onTap: onDismiss,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.brown[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.close, size: 18, color: Colors.brown[400]),
            ),
          ),
      ],
    );
  }

  Widget _buildCurrentCartSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.brown[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.brown[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_cart_outlined,
                  size: 16, color: Colors.brown[600]),
              const SizedBox(width: 8),
              Text(
                'الفاتورة الحالية',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.brown[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$currentCartCount منتجات | المجموع: ${NumberFormat.simpleCurrency().format(currentCartTotal)}',
            style: TextStyle(fontSize: 13, color: Colors.brown[500]),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: canPark ? onPark : null,
              style: TextButton.styleFrom(
                backgroundColor:
                    canPark ? Colors.brown[600] : Colors.brown[100],
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.brown[300],
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'ركن الفاتورة',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDivider() {
    return Container(height: 1, width: double.infinity, color: Colors.brown[100]);
  }

  Widget _buildParkedCartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.inbox_outlined, size: 16, color: Colors.brown[600]),
            const SizedBox(width: 8),
            Text(
              'الفواتير المعلقة',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.brown[700],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.brown[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${parkedCarts.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.brown[600],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (parkedCarts.isEmpty)
          _buildEmptyState()
        else
          ...parkedCarts.asMap().entries.map(
                (entry) => _buildParkedCart(entry.key, entry.value),
              ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.brown[200]),
          const SizedBox(height: 12),
          Text(
            'لا توجد فواتير معلقة',
            style: TextStyle(fontSize: 14, color: Colors.brown[300]),
          ),
        ],
      ),
    );
  }

  Widget _buildParkedCart(int index, ParkedCartData cart) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.brown[100]!),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_outlined, size: 20, color: Colors.brown[400]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cart.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.brown[800],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${cart.productCount} منتجات | المجموع: ${NumberFormat.simpleCurrency().format(cart.total)}',
                  style: TextStyle(fontSize: 12, color: Colors.brown[400]),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'استئناف',
            icon: Icon(Icons.play_arrow_rounded,
                color: Colors.brown[500], size: 22),
            constraints:
                const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: const EdgeInsets.all(6),
            onPressed: () => onRestore(index),
          ),
          IconButton(
            tooltip: 'حذف',
            icon: Icon(Icons.delete_outline,
                color: Colors.brown[300], size: 20),
            constraints:
                const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: const EdgeInsets.all(6),
            onPressed: () => onDelete(index),
          ),
        ],
      ),
    );
  }
}
