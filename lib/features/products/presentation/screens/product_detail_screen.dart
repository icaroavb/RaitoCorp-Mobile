import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/temperature_bar.dart';
import '../../../../shared/extensions/number_extensions.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/review_entity.dart';
import '../providers/products_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({required this.productId, super.key});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  LightTemperature _selectedTemp = LightTemperature.warm;
  bool _specsExpanded = false;
  bool _added = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productAsync = ref.watch(productByIdProvider(widget.productId));
    final reviewsAsync = ref.watch(productReviewsProvider(widget.productId));

    return productAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Erro: $e'))),
      data: (product) {
        if (product == null) {
          return const Scaffold(
            body: Center(child: Text('Produto não encontrado')),
          );
        }
        _selectedTemp = product.lightTemperature;
        return Scaffold(
          backgroundColor: AppColors.cream,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: AppColors.warmWhite,
                surfaceTintColor: Colors.transparent,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Material(
                    color: AppColors.warmWhite.withValues(alpha: 0.9),
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: Icon(PhosphorIcons.arrowLeft()),
                      onPressed: () => context.pop(),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Material(
                      color: AppColors.warmWhite.withValues(alpha: 0.9),
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: Icon(PhosphorIcons.shareNetwork()),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: 'product-image-${product.id}',
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrls.first,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.gray100),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: TemperatureBar(
                  temperature: product.lightTemperature,
                  height: 4,
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.warmWhite,
                  padding: const EdgeInsets.all(AppSpacing.page),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: theme.textTheme.displaySmall),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            product.price.formatCurrency(),
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ou 10x ${(product.price / 10).formatCurrency()} sem juros',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          for (int i = 0; i < 5; i++)
                            Icon(
                              PhosphorIcons.star(PhosphorIconsStyle.fill),
                              size: 16,
                              color: i < product.rating.floor()
                                  ? AppColors.amber400
                                  : AppColors.gray300,
                            ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${product.rating}',
                            style: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '· ${product.reviewCount} avaliações',
                            style: theme.textTheme.bodySmall?.copyWith(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Serve na minha casa?
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.page),
                  child: _FitsMyHomeCard(product: product),
                ),
              ),

              // Como vai ficar
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.warmWhite,
                  padding: const EdgeInsets.all(AppSpacing.page),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('COMO VAI FICAR',
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          for (final t in LightTemperature.values) ...[
                            Expanded(
                              child: _TempToggle(
                                label: t.label,
                                selected: _selectedTemp == t,
                                onTap: () =>
                                    setState(() => _selectedTemp = t),
                              ),
                            ),
                            if (t != LightTemperature.values.last)
                              const SizedBox(width: AppSpacing.sm),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ClipRRect(
                        borderRadius: AppRadius.md,
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: CachedNetworkImage(
                            imageUrl: product.imageUrls.length > 1
                                ? product.imageUrls[1]
                                : product.imageUrls.first,
                            fit: BoxFit.cover,
                            color: _overlayForTemp(_selectedTemp),
                            colorBlendMode: BlendMode.overlay,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Center(
                        child: Text(
                          '${product.name} em ${product.idealRooms.isNotEmpty ? product.idealRooms.first.label : ''} · ${_selectedTemp.label.toLowerCase()} ${product.colorTemperatureK}K',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Brightness bar
                      Row(
                        children: [
                          Text('Suave', style: theme.textTheme.bodySmall),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              child: LinearProgressIndicator(
                                value: product.brightnessLevel.sliderValue,
                                minHeight: 5,
                                backgroundColor: AppColors.gray200,
                                color: AppColors.amber400,
                              ),
                            ),
                          ),
                          Text('Intenso', style: theme.textTheme.bodySmall),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.amber100,
                            borderRadius: AppRadius.full,
                          ),
                          child: Text(
                            '${product.brightnessLevel.label} — ideal para quarto e sala',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.amber600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // O que você precisa saber
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.page),
                  child: _NeedToKnowAccordion(
                    product: product,
                    expanded: _specsExpanded,
                    onToggle: () =>
                        setState(() => _specsExpanded = !_specsExpanded),
                  ),
                ),
              ),

              // Reviews
              SliverToBoxAdapter(
                child: reviewsAsync.when(
                  data: (reviews) => Padding(
                    padding: const EdgeInsets.all(AppSpacing.page),
                    child: _ReviewsSection(
                      product: product,
                      reviews: reviews,
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
            ],
          ),
          bottomSheet: Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.md,
              AppSpacing.page,
              AppSpacing.md,
            ),
            decoration: const BoxDecoration(
              color: AppColors.warmWhite,
              border: Border(
                top: BorderSide(color: AppColors.gray100),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.price.formatCurrency(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '10x ${(product.price / 10).formatCurrency()}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _added
                          ? ElevatedButton.icon(
                              key: const ValueKey('added'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                              ),
                              onPressed: null,
                              icon: const Icon(Icons.check_circle_rounded,
                                  size: 18),
                              label: const Text('Adicionado!'),
                            )
                          : ElevatedButton.icon(
                              key: const ValueKey('add'),
                              icon: Icon(
                                PhosphorIcons.shoppingCart(
                                    PhosphorIconsStyle.fill),
                                size: 18,
                              ),
                              label: const Text('Adicionar ao carrinho →'),
                              onPressed: () => _addToCart(product),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _addToCart(ProductEntity product) async {
    ref.read(cartProvider.notifier).addProduct(product);
    setState(() => _added = true);
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
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _added = false);
  }

  Color _overlayForTemp(LightTemperature t) {
    return switch (t) {
      LightTemperature.warm =>
        AppColors.amber400.withValues(alpha: 0.15),
      LightTemperature.neutral => Colors.transparent,
      LightTemperature.cool =>
        const Color(0xFFA8C8E8).withValues(alpha: 0.12),
    };
  }
}

class _FitsMyHomeCard extends StatelessWidget {
  final ProductEntity product;
  const _FitsMyHomeCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      'Bocal ${product.socketType} — padrão em 90% dos apartamentos',
      if (product.isBivolt) 'Bivolt — funciona em 110V e 220V',
      'Cabo de 1m incluso — sem precisar de eletricista',
      'Encaixa em forro de gesso padrão',
    ];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.amber100,
        borderRadius: AppRadius.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.plug(PhosphorIconsStyle.fill),
                color: AppColors.amber600,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Serve na minha casa?',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    PhosphorIcons.checkCircle(),
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Text(
            '→ Não tenho certeza → Consultar o assistente',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.amber600,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
}

class _TempToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TempToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.sm,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.amber100 : AppColors.warmWhite,
          border: Border.all(
            color: selected ? AppColors.amber400 : AppColors.gray300,
            width: 1.5,
          ),
          borderRadius: AppRadius.sm,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? AppColors.amber600 : AppColors.gray500,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}

class _NeedToKnowAccordion extends StatelessWidget {
  final ProductEntity product;
  final bool expanded;
  final VoidCallback onToggle;
  const _NeedToKnowAccordion({
    required this.product,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = [
      (
        icon: PhosphorIcons.lightning(PhosphorIconsStyle.fill),
        title: 'Economia',
        value: 'Até ${product.energySavingPercent}% vs incandescente'
      ),
      (
        icon: PhosphorIcons.thermometer(PhosphorIconsStyle.fill),
        title: 'Temperatura',
        value:
            '${product.lightTemperature.label.replaceAll('Luz ', '').toUpperCase()[0]}${product.lightTemperature.label.replaceAll('Luz ', '').substring(1)} — aconchegante'
      ),
      (
        icon: PhosphorIcons.sun(PhosphorIconsStyle.fill),
        title: 'Intensidade',
        value: '${product.brightnessLevel.label} — para tarefas e relaxar'
      ),
      (
        icon: PhosphorIcons.clock(PhosphorIconsStyle.fill),
        title: 'Vida útil',
        value: '~${product.lifespanYears} anos sem trocar'
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'O que você precisa saber',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Icon(
                  expanded
                      ? PhosphorIcons.caretUp()
                      : PhosphorIcons.caretDown(),
                  size: 18,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(row.icon, size: 18, color: AppColors.amber600),
                  const SizedBox(width: AppSpacing.md),
                  Text(row.title, style: theme.textTheme.bodyMedium),
                  const Spacer(),
                  Text(
                    row.value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.obsidian,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  final ProductEntity product;
  final List<ReviewEntity> reviews;
  const _ReviewsSection({required this.product, required this.reviews});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('O QUE DIZEM OS CLIENTES', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${product.rating}',
                style: theme.textTheme.displayMedium,
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      for (int i = 0; i < 5; i++)
                        Icon(
                          PhosphorIcons.star(PhosphorIconsStyle.fill),
                          size: 16,
                          color: i < product.rating.floor()
                              ? AppColors.amber400
                              : AppColors.gray300,
                        ),
                    ],
                  ),
                  Text(
                    'de ${product.reviewCount} avaliações',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final r in reviews.take(3)) ...[
            _ReviewCard(review: r),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewEntity review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: AppRadius.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.obsidian,
                child: Text(
                  review.authorInitials,
                  style: const TextStyle(
                    color: AppColors.warmWhite,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  review.authorName,
                  style: theme.textTheme.labelLarge,
                ),
              ),
              Row(
                children: [
                  for (int i = 0; i < 5; i++)
                    Icon(
                      PhosphorIcons.star(PhosphorIconsStyle.fill),
                      size: 12,
                      color: i < review.rating
                          ? AppColors.amber400
                          : AppColors.gray300,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(review.comment, style: theme.textTheme.bodyMedium),
          if (review.room != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.amber100,
                borderRadius: AppRadius.full,
              ),
              child: Text(
                review.room!.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.amber600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
