import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  /// Rota para redirecionar após login bem-sucedido. Ex: '/checkout'
  final String? redirect;
  const LoginScreen({super.key, this.redirect});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  Future<void> _loginWithGoogle() async {
    setState(() { _loading = true; _error = null; });
    final ok = await ref.read(authProvider.notifier).loginWithGoogle();
    if (!mounted) return;
    if (ok) {
      context.go(widget.redirect ?? '/home');
    } else {
      final s = ref.read(authProvider);
      setState(() {
        _loading = false;
        _error = s is Unauthenticated ? s.errorMessage : null;
      });
    }
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    final ok = await ref
        .read(authProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text);
    if (!mounted) return;
    if (ok) {
      context.go(widget.redirect ?? '/home');
    } else {
      setState(() {
        _loading = false;
        _error = 'E-mail ou senha incorretos.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            const SizedBox(height: AppSpacing.xxl),
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.amber100,
                  borderRadius: AppRadius.full,
                ),
                child: Icon(
                  PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                  color: AppColors.amber600,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text('Raitõ', style: theme.textTheme.displaySmall),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.warmWhite,
                borderRadius: AppRadius.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bem-vindo de volta', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Continue de onde parou',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  InkWell(
                    onTap: () => context.go('/home'),
                    child: Text(
                      'Continuar sem conta →',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.amber600,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        PhosphorIcons.envelope(),
                        color: AppColors.gray400,
                        size: 20,
                      ),
                      hintText: 'seu@email.com',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        PhosphorIcons.lock(),
                        color: AppColors.gray400,
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? PhosphorIcons.eye() : PhosphorIcons.eyeSlash(),
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      hintText: '••••••••',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        'Esqueci minha senha',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.amber600,
                        ),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: AppRadius.sm,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              size: 16, color: AppColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                  color: AppColors.error, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  ElevatedButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.warmWhite,
                            ),
                          )
                        : const Text('Entrar'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.gray200)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('ou', style: theme.textTheme.bodySmall),
                      ),
                      const Expanded(child: Divider(color: AppColors.gray200)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton(
                    onPressed: _loading ? null : _loginWithGoogle,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4285F4),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'G',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Continuar com Google'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: () {
                      final dest = widget.redirect != null
                          ? '/register?redirect=${Uri.encodeComponent(widget.redirect!)}'
                          : '/register';
                      context.go(dest);
                    },
                    child: const Text('Criar conta grátis'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: Text(
                      'Esta é uma demonstração. Dados apenas para teste.',
                      style: theme.textTheme.bodySmall,
                    ),
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
