import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';
import '../errors/app_failure.dart';

class ApiClient {
  ApiClient(this._http);
  final http.Client _http;
  String? _sessionToken;
  static const _uuid = Uuid();

  void setSession(String? value) => _sessionToken = value;

  Future<Map<String, dynamic>> call(
    String function, [
    Map<String, dynamic> params = const {},
  ]) async {
    if (!AppConfig.isConfigured) {
      throw const AppFailure(
        'CONFIGURATION_ERROR',
        'Configure o endereço do Back4App e as versões dos Termos.',
      );
    }
    final url = Uri.parse(
      '${AppConfig.serverUrl.replaceAll(RegExp(r'/$'), '')}/functions/v1-$function',
    );
    try {
      final response = await _http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'X-Parse-Application-Id': AppConfig.applicationId,
              if (AppConfig.clientKey.isNotEmpty)
                'X-Parse-Client-Key': AppConfig.clientKey,
              if (_sessionToken != null)
                'X-Parse-Session-Token': _sessionToken!,
              'X-Correlation-Id': _uuid.v4(),
            },
            body: jsonEncode(params),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppFailure(
          response.statusCode == 401 ? 'AUTH_SESSION_EXPIRED' : 'NETWORK_ERROR',
          response.statusCode == 401
              ? 'Sua sessão expirou. Entre novamente.'
              : 'Não foi possível conectar ao servidor.',
        );
      }
      final parsed = jsonDecode(response.body);
      if (parsed is! Map<String, dynamic>) {
        throw const AppFailure(
          'INVALID_RESPONSE',
          'Resposta inesperada do servidor.',
        );
      }
      final result = parsed['result'];
      if (result is! Map<String, dynamic>) {
        throw const AppFailure(
          'INVALID_RESPONSE',
          'Resposta inesperada do servidor.',
        );
      }
      if (result['ok'] != true) {
        final error = result['error'];
        if (error is Map<String, dynamic>) {
          throw AppFailure(
            error['code']?.toString() ?? 'UNKNOWN_ERROR',
            error['message']?.toString() ?? 'Não foi possível concluir.',
            error['requestId']?.toString(),
          );
        }
        throw const AppFailure(
          'INVALID_RESPONSE',
          'Resposta inesperada do servidor.',
        );
      }
      final data = result['data'];
      if (data is! Map<String, dynamic>) {
        throw const AppFailure(
          'INVALID_RESPONSE',
          'Resposta inesperada do servidor.',
        );
      }
      return data;
    } on TimeoutException {
      throw const AppFailure(
        'TIMEOUT',
        'A conexão demorou demais. Tente novamente.',
      );
    } on FormatException {
      throw const AppFailure(
        'INVALID_RESPONSE',
        'Resposta inesperada do servidor.',
      );
    } on http.ClientException {
      throw const AppFailure('NETWORK_ERROR', 'Sem conexão com o servidor.');
    }
  }
}
