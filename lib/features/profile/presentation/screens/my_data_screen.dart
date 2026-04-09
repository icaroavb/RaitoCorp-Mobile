import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class MyDataScreen extends ConsumerStatefulWidget {
  const MyDataScreen({super.key});

  @override
  ConsumerState<MyDataScreen> createState() => _MyDataScreenState();
}

class _MyDataScreenState extends ConsumerState<MyDataScreen> {
  late final TextEditingController _nameCtl;
  late final TextEditingController _phoneCtl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameCtl = TextEditingController(text: user?.name ?? '');
    _phoneCtl = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _phoneCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(authProvider.notifier).updateProfile(
          name: _nameCtl.text.trim(),
          phone: _phoneCtl.text.trim(),
        );
    if (mounted) {
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados atualizados.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Meus dados'),
        backgroundColor: AppColors.cream,
        actions: [
          if (!_editing)
            IconButton(
              icon: Icon(PhosphorIcons.pencilSimple()),
              onPressed: () => setState(() => _editing = true),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          _Field(
            label: 'Nome completo',
            controller: _nameCtl,
            editing: _editing,
            icon: PhosphorIcons.user(),
          ),
          const SizedBox(height: AppSpacing.md),
          _Field(
            label: 'E-mail',
            controller: TextEditingController(text: user.email),
            editing: false,
            icon: PhosphorIcons.envelope(),
            subtitle: 'Para alterar, fale com o suporte.',
          ),
          const SizedBox(height: AppSpacing.md),
          _Field(
            label: 'Telefone',
            controller: _phoneCtl,
            editing: _editing,
            icon: PhosphorIcons.phone(),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9()\s-]')),
              LengthLimitingTextInputFormatter(16),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _Field(
            label: 'Data de nascimento',
            controller: TextEditingController(
              text: user.birthDate != null
                  ? DateFormat('dd/MM/yyyy').format(user.birthDate!)
                  : 'Não informada',
            ),
            editing: false,
            icon: PhosphorIcons.cake(),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.warmWhite,
              borderRadius: AppRadius.md,
              border: Border.all(color: AppColors.gray100),
            ),
            child: Row(
              children: [
                Icon(PhosphorIcons.shieldCheck(),
                    color: AppColors.success, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Seus dados estão protegidos pela LGPD.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          if (_editing) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Salvar alterações'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => setState(() {
                  _editing = false;
                  _nameCtl.text = user.name;
                  _phoneCtl.text = user.phone ?? '';
                }),
                child: const Text('Cancelar'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool editing;
  final IconData icon;
  final String? subtitle;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  const _Field({
    required this.label,
    required this.controller,
    required this.editing,
    required this.icon,
    this.subtitle,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: AppRadius.md,
        border: Border.all(
          color: editing ? AppColors.amber400 : AppColors.gray100,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: AppRadius.sm,
            ),
            child: Icon(icon, size: 18, color: AppColors.obsidian),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.gray500),
                ),
                TextField(
                  controller: controller,
                  enabled: editing,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  style: theme.textTheme.titleMedium,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.gray400, fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
