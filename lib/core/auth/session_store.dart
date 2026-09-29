import 'package:flutter/foundation.dart';
import 'package:signals/signals.dart';

import '../network/api_client.dart';

// Token kept only in memory on web. A page reload requires a new login.
class SessionStore extends ChangeNotifier {
  SessionStore(this.api);
  final ApiClient api;
  final user = signal<Map<String, dynamic>?>(null);
  final memberships = signal<List<dynamic>>([]);
  final workspaceId = signal<String?>(null);

  bool get isAuthenticated => user.value != null;

  Future<void> login(String email, String password) async {
    final data = await api.call('auth-login', {
      'email': email,
      'password': password,
    });
    final token = data['sessionToken'];
    if (token is! String || token.isEmpty) {
      throw StateError('O servidor não retornou uma sessão válida.');
    }
    api.setSession(token);
    try {
      await refresh();
    } catch (_) {
      api.setSession(null);
      rethrow;
    }
  }

  Future<void> refresh() async {
    final data = await api.call('auth-me');
    user.value = (data['user'] as Map).cast<String, dynamic>();
    memberships.value = (data['memberships'] as List?) ?? [];
    final first = memberships.value.cast<Map>().firstOrNull;
    workspaceId.value = first?['workspaceId']?.toString();
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      if (isAuthenticated) await api.call('auth-logout');
    } finally {
      api.setSession(null);
      user.value = null;
      memberships.value = [];
      workspaceId.value = null;
      notifyListeners();
    }
  }
}
