import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Sobe imagens pro Cloudinary via *unsigned upload preset*.
///
/// O app envia o arquivo direto pro Cloudinary (não passa pelo n8n, que é
/// hardened e tem limite de payload) e recebe de volta a `secure_url`, que é
/// o que guardamos no banco (`products.image_urls`, `reviews.photo_url`).
///
/// Config via `--dart-define` (defaults já preenchidos pra este projeto):
/// `CLOUDINARY_CLOUD_NAME` e `CLOUDINARY_UPLOAD_PRESET` (preset deve ser
/// *Unsigned* no painel do Cloudinary).
class CloudinaryService {
  CloudinaryService({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  Uri get _endpoint => Uri.parse(
        'https://api.cloudinary.com/v1_1/${AppConfig.cloudinaryCloudName}/image/upload',
      );

  /// Sobe os bytes de uma imagem e retorna a URL pública (`secure_url`).
  /// Lança [Exception] se o upload falhar.
  Future<String> uploadBytes(List<int> bytes, {String? filename}) async {
    final req = http.MultipartRequest('POST', _endpoint)
      ..fields['upload_preset'] = AppConfig.cloudinaryUploadPreset
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename ?? 'upload.jpg',
      ));

    final streamed = await _http.send(req).timeout(AppConfig.requestTimeout);
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final url = json['secure_url'] as String?;
      if (url == null || url.isEmpty) {
        throw Exception('Cloudinary não retornou a URL da imagem.');
      }
      return url;
    }
    throw Exception('Falha no upload da imagem (${res.statusCode}).');
  }

  void close() => _http.close();
}

final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  final service = CloudinaryService();
  ref.onDispose(service.close);
  return service;
});
