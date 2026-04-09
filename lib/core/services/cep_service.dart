import 'dart:convert';

import 'package:http/http.dart' as http;

class CepResult {
  final String street;
  final String neighborhood;
  final String city;
  final String state;

  const CepResult({
    required this.street,
    required this.neighborhood,
    required this.city,
    required this.state,
  });
}

/// Busca endereço pelo CEP.
/// Tenta ViaCEP primeiro; se falhar, usa BrasilAPI como fallback.
class CepService {
  static Future<CepResult?> lookup(String cep) async {
    final digits = cep.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return null;

    // 1ª tentativa: ViaCEP
    try {
      final res = await http
          .get(Uri.parse('https://viacep.com.br/ws/$digits/json/'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['erro'] != true) {
          return CepResult(
            street: (data['logradouro'] as String?) ?? '',
            neighborhood: (data['bairro'] as String?) ?? '',
            city: (data['localidade'] as String?) ?? '',
            state: (data['uf'] as String?) ?? '',
          );
        }
      }
    } catch (_) {}

    // Fallback: BrasilAPI
    try {
      final res = await http
          .get(Uri.parse('https://brasilapi.com.br/api/cep/v2/$digits'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return CepResult(
          street: (data['street'] as String?) ?? '',
          neighborhood: (data['neighborhood'] as String?) ?? '',
          city: (data['city'] as String?) ?? '',
          state: (data['state'] as String?) ?? '',
        );
      }
    } catch (_) {}

    return null;
  }
}
