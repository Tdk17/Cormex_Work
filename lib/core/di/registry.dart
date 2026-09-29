import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../auth/session_store.dart';
import '../network/api_client.dart';

final di = GetIt.instance;

void configureDependencies() {
  di.registerLazySingleton<http.Client>(() => http.Client());
  di.registerLazySingleton<ApiClient>(() => ApiClient(di<http.Client>()));
  di.registerLazySingleton<SessionStore>(() => SessionStore(di<ApiClient>()));
}
