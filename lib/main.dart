import 'package:flutter/material.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'core/di/registry.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  runApp(const CormexWorkApp());
}

class CormexWorkApp extends StatelessWidget {
  const CormexWorkApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'Cormex Work',
        debugShowCheckedModeBanner: false,
        theme: CormexTheme.light,
        routerConfig: appRouter,
      );
}
