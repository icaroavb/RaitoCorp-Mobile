import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/services/cep_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/address_entity.dart';
import '../providers/addresses_provider.dart';

// ── Lista de estados brasileiros (IBGE) ─────────────────────────────────────
const _brazilianStates = [
  'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO',
  'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI',
  'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
];

// ── Máscara XXXXX-XXX ────────────────────────────────────────────────────────
class _CepFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue next,
  ) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 5) {
      return next.copyWith(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
    }
    final formatted =
        '${digits.substring(0, 5)}-${digits.substring(5, digits.length.clamp(0, 8))}';
    return next.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

Future<void> showAddressFormSheet(
  BuildContext context,
  WidgetRef ref,
  String email,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.warmWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _AddressFormSheet(email: email),
  );
}

class _AddressFormSheet extends ConsumerStatefulWidget {
  final String email;
  const _AddressFormSheet({required this.email});

  @override
  ConsumerState<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends ConsumerState<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _label = TextEditingController(text: 'Casa');
  final _zip = TextEditingController();
  final _street = TextEditingController();
  final _number = TextEditingController();
  final _complement = TextEditingController();
  final _neighborhood = TextEditingController();
  final _city = TextEditingController();
  final _numberFocus = FocusNode();

  String? _selectedState;
  bool _loadingCep = false;
  String? _cepError;

  @override
  void dispose() {
    _label.dispose();
    _zip.dispose();
    _street.dispose();
    _number.dispose();
    _complement.dispose();
    _neighborhood.dispose();
    _city.dispose();
    _numberFocus.dispose();
    super.dispose();
  }

  // Chamado sempre que o CEP muda
  Future<void> _onCepChanged(String value) async {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return;

    setState(() {
      _loadingCep = true;
      _cepError = null;
    });

    final result = await CepService.lookup(digits);

    if (!mounted) return;
    setState(() => _loadingCep = false);

    if (result == null) {
      setState(() => _cepError = 'CEP não encontrado');
      return;
    }

    _street.text = result.street;
    _neighborhood.text = result.neighborhood;
    _city.text = result.city;
    setState(() => _selectedState = result.state.toUpperCase());

    // Foca no número após auto-fill
    _numberFocus.requestFocus();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final address = AddressEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: _label.text.trim(),
      street: _street.text.trim(),
      number: _number.text.trim(),
      complement:
          _complement.text.trim().isEmpty ? null : _complement.text.trim(),
      neighborhood: _neighborhood.text.trim(),
      city: _city.text.trim(),
      state: _selectedState ?? '',
      zipCode: _zip.text.trim(),
    );
    ref.read(addressesProvider.notifier).add(widget.email, address);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Endereço salvo.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.page,
        right: AppSpacing.page,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius: AppRadius.full,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Novo endereço', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),

              // Nome
              _input(_label, 'Nome (ex: Casa, Trabalho)'),
              const SizedBox(height: AppSpacing.md),

              // CEP com auto-fill
              TextFormField(
                controller: _zip,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _CepFormatter(),
                ],
                onChanged: _onCepChanged,
                decoration: InputDecoration(
                  labelText: 'CEP',
                  isDense: true,
                  suffixIcon: _loadingCep
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _cepError != null
                          ? Icon(PhosphorIcons.warning(),
                              color: AppColors.error, size: 20)
                          : _zip.text.replaceAll(RegExp(r'\D'), '').length == 8
                              ? Icon(PhosphorIcons.checkCircle(),
                                  color: AppColors.success, size: 20)
                              : null,
                  errorText: _cepError,
                  helperText:
                      'Digite o CEP para preencher o endereço automaticamente',
                  helperStyle: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.gray500),
                ),
                validator: (v) =>
                    (v == null || v.replaceAll(RegExp(r'\D'), '').length != 8)
                        ? 'CEP inválido'
                        : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // Rua + Número
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _input(_street, 'Rua / Logradouro'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _input(
                      _number,
                      'Nº',
                      keyboardType: TextInputType.number,
                      focusNode: _numberFocus,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              _input(_complement, 'Complemento (opcional)', required: false),
              const SizedBox(height: AppSpacing.md),
              _input(_neighborhood, 'Bairro'),
              const SizedBox(height: AppSpacing.md),

              // Cidade + Estado (dropdown)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _input(_city, 'Cidade')),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedState,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'UF',
                        isDense: true,
                      ),
                      items: _brazilianStates
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedState = v),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Obrigatório' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Salvar endereço'),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController c,
    String label, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    bool required = true,
    FocusNode? focusNode,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null
          : null,
    );
  }
}
