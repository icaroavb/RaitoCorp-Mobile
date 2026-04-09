import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_colors.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int cartBadgeCount;

  const AppBottomNavBar({
    required this.currentIndex,
    required this.onTap,
    this.cartBadgeCount = 0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.warmWhite,
        border: Border(top: BorderSide(color: AppColors.gray100, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              _buildItem(
                context,
                index: 0,
                icon: PhosphorIcons.house(),
                activeIcon: PhosphorIcons.house(PhosphorIconsStyle.fill),
                label: 'Início',
              ),
              _buildItem(
                context,
                index: 1,
                icon: PhosphorIcons.package(),
                activeIcon: PhosphorIcons.package(PhosphorIconsStyle.fill),
                label: 'Produtos',
              ),
              _buildItem(
                context,
                index: 2,
                icon: PhosphorIcons.sparkle(),
                activeIcon: PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                label: 'Consultor',
              ),
              _buildItem(
                context,
                index: 3,
                icon: PhosphorIcons.shoppingCart(),
                activeIcon:
                    PhosphorIcons.shoppingCart(PhosphorIconsStyle.fill),
                label: 'Carrinho',
                badgeCount: cartBadgeCount,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int badgeCount = 0,
  }) {
    final isSelected = currentIndex == index;
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Indicador âmbar em cima do ícone selecionado
            Container(
              height: 3,
              width: 28,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.amber400 : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 22,
                  color:
                      isSelected ? AppColors.obsidian : AppColors.gray400,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -6,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.obsidian,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: AppColors.warmWhite,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color:
                    isSelected ? AppColors.obsidian : AppColors.gray500,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
