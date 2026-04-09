import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/mock/mock_products.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/review_entity.dart';

class ProductFilter {
  final String query;
  final ProductCategory? category;
  final Room? room;

  const ProductFilter({this.query = '', this.category, this.room});

  ProductFilter copyWith({
    String? query,
    ProductCategory? category,
    Room? room,
    bool clearCategory = false,
    bool clearRoom = false,
  }) {
    return ProductFilter(
      query: query ?? this.query,
      category: clearCategory ? null : (category ?? this.category),
      room: clearRoom ? null : (room ?? this.room),
    );
  }
}

final productFilterProvider =
    StateProvider<ProductFilter>((ref) => const ProductFilter());

final allProductsProvider = FutureProvider<List<ProductEntity>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 400));
  return mockProducts;
});

final filteredProductsProvider = Provider<AsyncValue<List<ProductEntity>>>((ref) {
  final productsAsync = ref.watch(allProductsProvider);
  final filter = ref.watch(productFilterProvider);
  return productsAsync.whenData((list) {
    return list.where((p) {
      if (filter.query.isNotEmpty) {
        final q = filter.query.toLowerCase();
        final matches = p.name.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q) ||
            p.tags.any((t) => t.toLowerCase().contains(q));
        if (!matches) return false;
      }
      if (filter.category != null && p.category != filter.category) {
        return false;
      }
      if (filter.room != null && !p.idealRooms.contains(filter.room)) {
        return false;
      }
      return true;
    }).toList();
  });
});

final bestSellersProvider = Provider<AsyncValue<List<ProductEntity>>>((ref) {
  return ref
      .watch(allProductsProvider)
      .whenData((list) => list.where((p) => p.isBestSeller).toList());
});

final productByIdProvider =
    Provider.family<AsyncValue<ProductEntity?>, String>((ref, id) {
  return ref.watch(allProductsProvider).whenData(
        (list) => list.where((p) => p.id == id).firstOrNull,
      );
});

final productReviewsProvider =
    FutureProvider.family<List<ReviewEntity>, String>((ref, productId) async {
  await Future.delayed(const Duration(milliseconds: 200));
  return mockReviews;
});
