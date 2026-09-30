import 'dart:convert';

import 'package:http/http.dart' as http;

class IbgeLocation {
  const IbgeLocation({required this.id, required this.name, this.code});
  final int id;
  final String name;
  final String? code;
}

class IbgeLocations {
  IbgeLocations(this.client);
  final http.Client client;
  static const base = 'https://servicodados.ibge.gov.br/api/v1/localidades';
  Future<List<IbgeLocation>>? _states;
  final Map<String, Future<List<IbgeLocation>>> _cities = {};

  Future<List<IbgeLocation>> get states =>
      _states ??= _fetch('$base/estados', includeCode: true);

  Future<List<IbgeLocation>> cities(String state) {
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(state)) {
      throw const FormatException('Selecione um estado válido.');
    }
    return _cities.putIfAbsent(
      state,
      () => _fetch('$base/estados/$state/municipios'),
    );
  }

  Future<List<IbgeLocation>> _fetch(String url,
      {bool includeCode = false}) async {
    try {
      final response = await client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        throw const FormatException('Consulta de localidades indisponível.');
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! List) throw const FormatException('Resposta inválida.');
      final values = data.map((item) {
        if (item is! Map || item['id'] is! int || item['nome'] is! String) {
          throw const FormatException('Resposta inválida.');
        }
        final code = includeCode ? item['sigla'] : null;
        if (includeCode && (code is! String ||
            !RegExp(r'^[A-Z]{2}$').hasMatch(code))) {
          throw const FormatException('Resposta inválida.');
        }
        return IbgeLocation(
          id: item['id'] as int,
          name: item['nome'] as String,
          code: code as String?,
        );
      }).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return values;
    } catch (_) {
      // A failed request can be retried without retaining stale errors.
      _states = null;
      _cities.clear();
      rethrow;
    }
  }
}
