import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/upload/cloudinary_service.dart';
import '../../../../core/upload/image_source_sheet.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../providers/admin_provider.dart';

/// Formulário de criar/editar produto. Se [existing] for nulo, cria; senão edita.
/// Faz upload da imagem pro Cloudinary e guarda a URL em `image_urls`.
class NewProductForm extends ConsumerStatefulWidget {
  final ProductEntity? existing;
  final VoidCallback? onSaved;
  const NewProductForm({super.key, this.existing, this.onSaved});

  @override
  ConsumerState<NewProductForm> createState() => _NewProductFormState();
}

class _NewProductFormState extends ConsumerState<NewProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _socket;
  late final TextEditingController _powerWatts;
  late final TextEditingController _lumens;
  late final TextEditingController _tags;

  ProductCategory _category = ProductCategory.lamp;
  LightTemperature _light = LightTemperature.warm;
  bool _bestSeller = false;

  /// URL da imagem já no Cloudinary (uma só, pra simplificar).
  String? _imageUrl;
  bool _uploading = false;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _name = TextEditingController(text: p?.name ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(text: p != null ? p.price.toString() : '');
    _socket = TextEditingController(text: p?.socketType ?? 'E27');
    _powerWatts =
        TextEditingController(text: p != null ? p.powerWatts.toString() : '');
    _lumens = TextEditingController(text: p != null ? p.lumens.toString() : '');
    _tags = TextEditingController(text: p?.tags.join(', ') ?? '');
    if (p != null) {
      _category = p.category;
      _light = p.lightTemperature;
      _bestSeller = p.isBestSeller;
      _imageUrl = p.imageUrls.isNotEmpty ? p.imageUrls.first : null;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _socket.dispose();
    _powerWatts.dispose();
    _lumens.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    final file = await pickImageWithSource(context);
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final url = await ref
          .read(cloudinaryServiceProvider)
          .uploadBytes(bytes, filename: file.name);
      if (mounted) setState(() => _imageUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha no upload: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione uma imagem do produto.')),
      );
      return;
    }
    setState(() => _saving = true);

    final product = <String, dynamic>{
      if (_isEdit) 'id': widget.existing!.id,
      'name': _name.text.trim(),
      'description': _description.text.trim(),
      'price': double.tryParse(_price.text.replaceAll(',', '.')) ?? 0,
      'image_urls': [_imageUrl],
      'light_temperature': _light.name,
      'socket_type': _socket.text.trim(),
      'power_watts': int.tryParse(_powerWatts.text) ?? 0,
      'lumens': int.tryParse(_lumens.text) ?? 0,
      'category': _category.name,
      'is_best_seller': _bestSeller,
      'tags': _tags.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
    };

    try {
      final notifier = ref.read(adminProductsProvider.notifier);
      if (_isEdit) {
        await notifier.update(product);
      } else {
        await notifier.create(product);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Produto atualizado!' : 'Produto criado!')),
      );
      widget.onSaved?.call();
      if (!_isEdit) _resetForm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _name.clear();
    _description.clear();
    _price.clear();
    _powerWatts.clear();
    _lumens.clear();
    _tags.clear();
    setState(() {
      _imageUrl = null;
      _bestSeller = false;
      _category = ProductCategory.lamp;
      _light = LightTemperature.warm;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagem
          GestureDetector(
            onTap: _uploading ? null : _pickAndUpload,
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray200),
                image: _imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_imageUrl!), fit: BoxFit.cover)
                    : null,
              ),
              child: _uploading
                  ? const Center(child: CircularProgressIndicator())
                  : _imageUrl == null
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_a_photo_outlined,
                                  color: AppColors.gray400, size: 32),
                              SizedBox(height: 8),
                              Text('Toque para adicionar imagem',
                                  style: TextStyle(color: AppColors.gray500)),
                            ],
                          ),
                        )
                      : Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.black54,
                                  radius: 16,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.edit,
                                        size: 16, color: Colors.white),
                                    onPressed: _pickAndUpload,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                CircleAvatar(
                                  backgroundColor: Colors.black54,
                                  radius: 16,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.close,
                                        size: 16, color: Colors.white),
                                    onPressed: () =>
                                        setState(() => _imageUrl = null),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _field(_name, 'Nome', required: true),
          _field(_description, 'Descrição', maxLines: 3),
          _field(_price, 'Preço (R\$)',
              keyboardType: TextInputType.number, required: true),
          Row(
            children: [
              Expanded(child: _field(_powerWatts, 'Watts', keyboardType: TextInputType.number)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _field(_lumens, 'Lúmens', keyboardType: TextInputType.number)),
            ],
          ),
          _field(_socket, 'Soquete (ex: E27)'),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<ProductCategory>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Categoria'),
            items: ProductCategory.values
                .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                .toList(),
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<LightTemperature>(
            initialValue: _light,
            decoration: const InputDecoration(labelText: 'Temperatura de luz'),
            items: LightTemperature.values
                .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                .toList(),
            onChanged: (v) => setState(() => _light = v ?? _light),
          ),
          const SizedBox(height: AppSpacing.md),
          _field(_tags, 'Tags (separadas por vírgula)'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mais vendido'),
            value: _bestSeller,
            activeThumbColor: AppColors.amber400,
            onChanged: (v) => setState(() => _bestSeller = v),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEdit ? 'Salvar alterações' : 'Cadastrar produto'),
            ),
          ),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null
            : null,
      ),
    );
  }
}
