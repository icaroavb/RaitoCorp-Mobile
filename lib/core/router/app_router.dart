import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/screens/admin_hub_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/cart/presentation/screens/checkout_screen.dart';
import '../../features/cart/presentation/screens/checkout_success_screen.dart';
import '../../features/consultant/presentation/screens/consultant_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/products/presentation/screens/product_detail_screen.dart';
import '../../features/products/presentation/screens/product_list_screen.dart';
import '../../features/profile/presentation/screens/addresses_screen.dart';
import '../../features/profile/presentation/screens/favorites_screen.dart';
import '../../features/profile/presentation/screens/my_data_screen.dart';
import '../../features/profile/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/order_detail_screen.dart';
import '../../features/profile/presentation/screens/orders_screen.dart';
import '../../features/profile/presentation/screens/review_order_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/reviews_screen.dart';
import '../widgets/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      // ── Shell (com bottom nav) ───────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (_, _) => _fadePage(const HomeScreen()),
          ),
          GoRoute(
            path: '/products',
            pageBuilder: (_, _) => _fadePage(const ProductListScreen()),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (_, state) => _fadePage(
                  ProductDetailScreen(
                      productId: state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/consultant',
            pageBuilder: (_, _) => _fadePage(const ConsultantScreen()),
          ),
          GoRoute(
            path: '/cart',
            pageBuilder: (_, _) => _fadePage(const CartScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (_, _) => _fadePage(const ProfileScreen()),
          ),

          // ── Perfil — sub-páginas (mantêm a bottom nav) ──────────────────
          GoRoute(
            path: '/profile/orders',
            pageBuilder: (_, _) => _slidePage(const OrdersScreen()),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (_, state) => _slidePage(
                  OrderDetailScreen(orderId: state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/profile/favorites',
            pageBuilder: (_, _) => _slidePage(const FavoritesScreen()),
          ),
          GoRoute(
            path: '/profile/reviews',
            pageBuilder: (_, _) => _slidePage(const ReviewsScreen()),
          ),
          GoRoute(
            path: '/profile/addresses',
            pageBuilder: (_, _) => _slidePage(const AddressesScreen()),
          ),
          GoRoute(
            path: '/profile/my-data',
            pageBuilder: (_, _) => _slidePage(const MyDataScreen()),
          ),
          GoRoute(
            path: '/profile/notifications',
            pageBuilder: (_, _) => _slidePage(const NotificationsScreen()),
          ),
          GoRoute(
            path: '/profile/admin',
            pageBuilder: (_, _) => _slidePage(const AdminHubScreen()),
          ),
          GoRoute(
            path: '/profile/orders/:id/review',
            pageBuilder: (_, state) => _slidePage(
              ReviewOrderScreen(orderId: state.pathParameters['id']!),
            ),
          ),

          // ── Checkout — dentro do shell para manter a nav ─────────────────
          GoRoute(
            path: '/checkout',
            pageBuilder: (_, _) => _slidePage(const CheckoutScreen()),
          ),
          GoRoute(
            path: '/checkout/success/:orderId',
            pageBuilder: (_, state) => _fadePage(
              CheckoutSuccessScreen(
                  orderId: state.pathParameters['orderId']!),
            ),
          ),
        ],
      ),

      // ── Auth — sem bottom nav (telas isoladas) ───────────────────────────
      GoRoute(
        path: '/login',
        builder: (_, state) => LoginScreen(
          redirect: state.uri.queryParameters['redirect'],
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (_, state) => RegisterScreen(
          redirect: state.uri.queryParameters['redirect'],
        ),
      ),
    ],
  );
});

/// Transição de fade suave (tabs principais).
CustomTransitionPage<T> _fadePage<T>(Widget child) {
  return CustomTransitionPage<T>(
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

/// Slide da direita para a esquerda (sub-páginas / drill-down).
CustomTransitionPage<T> _slidePage<T>(Widget child) {
  return CustomTransitionPage<T>(
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (_, animation, _, child) {
      final tween = Tween(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}
