import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Mostra um bottom sheet pra o usuário escolher entre câmera e galeria, e
/// retorna o `XFile` escolhido (ou null se cancelou). Reutilizado no cadastro
/// de produto (admin) e na avaliação do cliente.
Future<XFile?> pickImageWithSource(
  BuildContext context, {
  int maxWidth = 1200,
  int imageQuality = 85,
}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Tirar foto'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Escolher da galeria'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;
  return ImagePicker().pickImage(
    source: source,
    maxWidth: maxWidth.toDouble(),
    imageQuality: imageQuality,
  );
}
