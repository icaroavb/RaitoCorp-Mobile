import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../products/presentation/providers/products_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showFirstTime = false;

  @override
  void initState() {
    super.initState();
    _loadFirstTime();
  }

  Future<void> _loadFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('hasSeenOnboarding') ?? false;
    if (mounted) setState(() => _showFirstTime = !hasSeen);
  }

  Future<void> _dismissFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (mounted) setState(() => _showFirstTime = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bestSellersAsync = ref.watch(bestSellersProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: RefreshIndicator(
        color: AppColors.amber400,
        onRefresh: () async {
          ref.invalidate(allProductsProvider);
          await Future.delayed(const Duration(milliseconds: 400));
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.warmWhite,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 1,
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Raitõ',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'ILUMINAÇÃO',
                      style: theme.textTheme.titleSmall?.copyWith(
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(PhosphorIcons.magnifyingGlass()),
                  onPressed: () => context.go('/products'),
                ),
                if (user != null)
                  GestureDetector(
                    onTap: () => context.go('/profile'),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.obsidian,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        user.initials,
                        style: const TextStyle(
                          color: AppColors.amber400,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                else
                  IconButton(
                    icon: Icon(PhosphorIcons.user()),
                    onPressed: () => context.push('/login'),
                  ),
                const SizedBox(width: 4),
              ],
            ),
            if (_showFirstTime)
              SliverToBoxAdapter(
                child: _FirstTimeBanner(onClose: _dismissFirstTime),
              ),
            SliverToBoxAdapter(child: _HeroBanner()),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            const SliverToBoxAdapter(child: _CategorySection()),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Mais vendidos', style: theme.textTheme.titleLarge),
                    TextButton(
                      onPressed: () => context.go('/products'),
                      child: Text(
                        'Ver todos →',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.amber600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            bestSellersAsync.when(
              data: (list) => SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                sliver: SliverList.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.lg),
                  itemBuilder: (context, i) {
                    final product = list[i];
                    return ProductCard(
                      product: product,
                      onTap: () => context.go('/products/${product.id}'),
                      onAddToCart: () {
                        ref.read(cartProvider.notifier).addProduct(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} adicionado'),
                            action: SnackBarAction(
                              label: 'Ver carrinho',
                              textColor: AppColors.amber400,
                              onPressed: () => context.go('/cart'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Text('Erro: $e'),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
            const SliverToBoxAdapter(child: _WhyBuyHereSection()),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            const SliverToBoxAdapter(child: _AiCtaBanner()),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            const SliverToBoxAdapter(child: _FirstPurchaseBanner()),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.huge)),
          ],
        ),
      ),
    );
  }
}

class _FirstTimeBanner extends StatelessWidget {
  final VoidCallback onClose;
  const _FirstTimeBanner({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.lg,
        AppSpacing.page,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.warmWhite,
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.amber100,
                borderRadius: AppRadius.sm,
              ),
              alignment: Alignment.center,
              child: Icon(
                PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                color: AppColors.amber600,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Primeira vez aqui?',
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    'Consultar o assistente →',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.amber600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(PhosphorIcons.x(), size: 18),
              onPressed: onClose,
              color: AppColors.gray500,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.xxl,
        AppSpacing.page,
        0,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.lg,
        child: Stack(
          children: [
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl:
                    'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=1200',
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.gray100),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amber400,
                      borderRadius: AppRadius.full,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                          size: 12,
                          color: AppColors.obsidian,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '+200 ambientes transformados',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.obsidian,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Sua casa merece\numa luz melhor',
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: AppColors.warmWhite,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Descubra a iluminação ideal para cada ambiente — sem precisar entender lúmens ou watts.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.warmWhite.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  OutlinedButton(
                    onPressed: () => GoRouter.of(context).go('/products'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.warmWhite,
                      side: BorderSide.none,
                      foregroundColor: AppColors.obsidian,
                      minimumSize: const Size(180, 48),
                    ),
                    child: const Text('Ver produtos  →'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = [
      (label: 'Quarto', hint: 'Luz suave', icon: PhosphorIcons.moon()),
      (label: 'Sala', hint: 'Destaque', icon: PhosphorIcons.armchair()),
      (label: 'Cozinha', hint: 'Funcional', icon: PhosphorIcons.chefHat()),
      (label: 'Externo', hint: 'À prova', icon: PhosphorIcons.tree()),
      (label: 'Office', hint: 'Foco', icon: PhosphorIcons.desktop()),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          child: Text(
            'ILUMINAR QUAL AMBIENTE?',
            style: theme.textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, i) {
              final c = categories[i];
              return Container(
                width: 100,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warmWhite,
                  borderRadius: AppRadius.md,
                  border: Border.all(color: AppColors.gray200),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(c.icon, size: 22, color: AppColors.amber600),
                    const SizedBox(height: 8),
                    Text(
                      c.label,
                      style: theme.textTheme.labelLarge,
                    ),
                    Text(
                      c.hint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.amber600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WhyBuyHereSection extends StatelessWidget {
  const _WhyBuyHereSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      (
        icon: PhosphorIcons.lightning(PhosphorIconsStyle.fill),
        title: 'Economize até 80%',
        subtitle: 'Na conta de luz comparado a lâmpadas incandescentes',
      ),
      (
        icon: PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
        title: '5 anos de garantia',
        subtitle: 'Pode confiar — cada produto testado antes de chegar até você',
      ),
      (
        icon: PhosphorIcons.medal(PhosphorIconsStyle.fill),
        title: 'Qualidade certificada',
        subtitle: 'Produtos com certificação INMETRO e padrão internacional',
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('POR QUE COMPRAR AQUI?', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: AppRadius.md,
            ),
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.obsidian,
                          borderRadius: AppRadius.sm,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          items[i].icon,
                          size: 18,
                          color: AppColors.warmWhite,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              items[i].title,
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              items[i].subtitle,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (i < items.length - 1)
                    const SizedBox(height: AppSpacing.lg),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiCtaBanner extends StatelessWidget {
  const _AiCtaBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: AppColors.navyDark,
          borderRadius: AppRadius.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
              color: AppColors.amber400,
              size: 28,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Não sabe qual escolher?',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.warmWhite,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Manda uma foto do seu ambiente. A gente analisa e indica a iluminação certa.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.warmWhite.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: () => GoRouter.of(context).go('/consultant'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.amber400,
                side: const BorderSide(color: AppColors.amber400, width: 1.5),
                minimumSize: const Size(180, 44),
              ),
              child: const Text('✦ Consultar grátis'),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Mais de 1.200 dúvidas respondidas essa semana',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.amber400.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FirstPurchaseBanner extends StatelessWidget {
  const _FirstPurchaseBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: AppColors.amber100,
          borderRadius: AppRadius.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '10% de desconto na primeira compra',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Crie sua conta gratuita em 30 segundos',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => GoRouter.of(context).go('/register'),
                child: const Text('Criar conta'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton(
                onPressed: () {},
                child: Text(
                  'Continuar sem conta →',
                  style: theme.textTheme.labelLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
