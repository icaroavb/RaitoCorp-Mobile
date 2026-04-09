import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../products/domain/entities/product_entity.dart';
import '../../domain/entities/cart_item_entity.dart';

const _cartBoxName = 'cart_box';

class CartNotifier extends StateNotifier<List<CartItemEntity>> {
  CartNotifier() : super(const []) {
    _loadFromBox();
  }

  Box<dynamic>? _box;

  Future<void> _loadFromBox() async {
    _box = await Hive.openBox<dynamic>(_cartBoxName);
    final rawItems = _box!.get('items', defaultValue: <dynamic>[]) as List;
    state = rawItems.map((raw) {
      final m = Map<String, dynamic>.from(raw as Map);
      return CartItemEntity(
        productId: m['productId'] as String,
        productName: m['productName'] as String,
        subtitle: m['subtitle'] as String? ?? '',
        price: (m['price'] as num).toDouble(),
        quantity: m['quantity'] as int,
        imageUrl: m['imageUrl'] as String,
      );
    }).toList();
  }

  Future<void> _persist() async {
    if (_box == null) return;
    await _box!.put(
      'items',
      state
          .map((i) => {
                'productId': i.productId,
                'productName': i.productName,
                'subtitle': i.subtitle,
                'price': i.price,
                'quantity': i.quantity,
                'imageUrl': i.imageUrl,
              })
          .toList(),
    );
  }

  void addProduct(ProductEntity product) {
    final existing = state.where((i) => i.productId == product.id).firstOrNull;
    if (existing != null) {
      state = state
          .map((i) => i.productId == product.id
              ? i.copyWith(quantity: i.quantity + 1)
              : i)
          .toList();
    } else {
      state = [
        ...state,
        CartItemEntity(
          productId: product.id,
          productName: product.name,
          subtitle: product.idealRooms.isNotEmpty
              ? 'Ideal para ${product.idealRooms.first.label}'
              : product.tags.isNotEmpty
                  ? product.tags.first
                  : '',
          price: product.price,
          quantity: 1,
          imageUrl: product.imageUrls.first,
        ),
      ];
    }
    _persist();
  }

  void removeItem(String productId) {
    state = state.where((i) => i.productId != productId).toList();
    _persist();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    state = state
        .map((i) =>
            i.productId == productId ? i.copyWith(quantity: quantity) : i)
        .toList();
    _persist();
  }

  void clear() {
    state = [];
    _persist();
  }

  int get totalItems => state.fold(0, (sum, i) => sum + i.quantity);
  double get subtotal => state.fold(0.0, (sum, i) => sum + i.subtotal);
}

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItemEntity>>((ref) {
  return CartNotifier();
});

final cartTotalItemsProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).fold<int>(0, (sum, i) => sum + i.quantity);
});

final cartSubtotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).fold<double>(0.0, (sum, i) => sum + i.subtotal);
});
