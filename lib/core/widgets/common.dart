import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../auth/session_store.dart';
import '../config/app_config.dart';
import '../di/registry.dart';

class Brand extends StatelessWidget {
  const Brand({super.key, this.light = false});
  final bool light;
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: light ? CormexTheme.sage : CormexTheme.petroleum,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              'W',
              style: TextStyle(
                color: light ? CormexTheme.deep : Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.5,
              ),
            ),
          ),
          const SizedBox(width: 11),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
              children: [
                TextSpan(
                  text: 'Cormex ',
                  style: TextStyle(
                    color: light ? Colors.white : CormexTheme.deep,
                  ),
                ),
                TextSpan(
                  text: 'Work',
                  style: TextStyle(
                    color: light ? CormexTheme.sage : CormexTheme.forest,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

class PublicFrame extends StatelessWidget {
  const PublicFrame({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          toolbarHeight: 76,
          title: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.go('/'),
            child: const Brand(),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: SizedBox(
              height: 1,
              child: ColoredBox(color: CormexTheme.border),
            ),
          ),
          actions: MediaQuery.sizeOf(context).width < 780
              ? [
                  PopupMenuButton<String>(
                    tooltip: 'Menu',
                    onSelected: (path) => context.go(path),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                          value: '/find', child: Text('Encontrar serviços')),
                      if (di<SessionStore>().isAuthenticated)
                        const PopupMenuItem(
                            value: '/my-bookings',
                            child: Text('Minhas reservas')),
                      if (!di<SessionStore>().isAuthenticated)
                        const PopupMenuItem(
                            value: '/login', child: Text('Entrar')),
                      const PopupMenuItem(
                          value: '/onboarding', child: Text('Sou empresa')),
                    ],
                  ),
                ]
              : [
                  TextButton(
                    onPressed: () => context.go('/find'),
                    child: const Text('Encontrar serviços'),
                  ),
                  if (di<SessionStore>().isAuthenticated)
                    TextButton(
                      onPressed: () => context.go('/my-bookings'),
                      child: const Text('Minhas reservas'),
                    ),
                  if (MediaQuery.sizeOf(context).width > 540 &&
                      !di<SessionStore>().isAuthenticated)
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Entrar'),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 22),
                    child: FilledButton(
                      onPressed: () => context.go('/onboarding'),
                      child: const Text('Sou empresa'),
                    ),
                  ),
                ],
        ),
        body: child,
      );
}

class PageWidth extends StatelessWidget {
  const PageWidth({super.key, required this.child, this.maxWidth = 1100});
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width < 600 ? 18 : 28,
            ),
            child: child,
          ),
        ),
      );
}

class Notice extends StatelessWidget {
  const Notice({super.key, required this.message, this.retry});
  final String message;
  final VoidCallback? retry;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: CormexTheme.pale,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: CormexTheme.forest,
                ),
              ),
              const SizedBox(height: 14),
              Text(message, textAlign: TextAlign.center),
              if (retry != null) ...[
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: retry,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ],
          ),
        ),
      );
}

class RemoteData extends StatelessWidget {
  const RemoteData({
    super.key,
    required this.future,
    required this.builder,
    required this.retry,
  });
  final Future<Map<String, dynamic>> future;
  final Widget Function(Map<String, dynamic>) builder;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(50),
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasError) {
            return Notice(message: snapshot.error.toString(), retry: retry);
          }
          return builder(snapshot.data!);
        },
      );
}

class ConfigurationGate extends StatelessWidget {
  const ConfigurationGate({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => AppConfig.isConfigured
      ? child
      : const Scaffold(
          body: PageWidth(
            child: Notice(
              message: 'Esta função estará disponível quando a operação do '
                  'Cormex Work estiver pronta.',
            ),
          ),
        );
}
