import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/cart/presentation/providers/cart_provider.dart';
import 'bottom_nav_bar.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({required this.child, super.key});

  static const _tabs = ['/home', '/products', '/consultant', '/cart'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    var currentIndex = _tabs.indexWhere((t) => location.startsWith(t));
    if (currentIndex < 0) currentIndex = 0;
    final cartCount = ref.watch(cartTotalItemsProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: currentIndex,
        cartBadgeCount: cartCount,
        onTap: (index) => context.go(_tabs[index]),
      ),
    );
  }
}
