import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/session_store.dart';
import '../core/di/registry.dart';
import '../core/widgets/common.dart';
import 'theme.dart';

class WorkShell extends StatelessWidget {
  const WorkShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 860;
    final section = _titleFor(GoRouterState.of(context).uri.path);
    return Scaffold(
      appBar: wide
          ? null
          : AppBar(
              title: const Brand(),
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: SizedBox(
                  height: 1,
                  child: ColoredBox(color: CormexTheme.border),
                ),
              ),
            ),
      drawer: wide
          ? null
          : Drawer(
              backgroundColor: CormexTheme.deep,
              child: SafeArea(
                child: Builder(builder: (drawerContext) => _menu(drawerContext)),
              ),
            ),
      body: Row(
        children: [
          if (wide)
            Container(
              width: 258,
              color: CormexTheme.deep,
              child: SafeArea(child: _menu(context)),
            ),
          Expanded(
            child: Column(
              children: [
                if (wide)
                  Container(
                    height: 76,
                    padding: const EdgeInsets.symmetric(horizontal: 34),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: CormexTheme.border),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          section,
                          style: const TextStyle(
                            color: CormexTheme.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: CormexTheme.pale,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.business_outlined,
                                size: 17,
                                color: CormexTheme.forest,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Área da empresa',
                                style: TextStyle(
                                  color: CormexTheme.petroleum,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _titleFor(String path) => switch (path) {
        '/app/dashboard' => 'Visão geral',
        '/app/services' => 'Serviços',
        '/app/bookings' => 'Reservas',
        '/app/hours' => 'Horários',
        '/app/plan' => 'Plano',
        '/app/settings' => 'Empresa',
        _ => 'Cormex Work',
      };

  Widget _menu(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(23, 24, 18, 19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Brand(light: true),
                SizedBox(height: 12),
                Text(
                  'Sua operação, com clareza.',
                  style: TextStyle(
                    color: Color(0xFF9EB8B2),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF294A4C), height: 1),
          const Padding(
            padding: EdgeInsets.fromLTRB(23, 26, 16, 12),
            child: Text(
              'ESPAÇO DE TRABALHO',
              style: TextStyle(
                color: Color(0xFF8CACAA),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          _link(context, Icons.space_dashboard_outlined, 'Visão geral',
              '/app/dashboard'),
          _link(context, Icons.design_services_outlined, 'Serviços',
              '/app/services'),
          _link(context, Icons.calendar_month_outlined, 'Reservas',
              '/app/bookings'),
          _link(context, Icons.access_time_outlined, 'Horários', '/app/hours'),
          const Padding(
            padding: EdgeInsets.fromLTRB(23, 24, 16, 12),
            child: Text(
              'GESTÃO',
              style: TextStyle(
                color: Color(0xFF8CACAA),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          _link(context, Icons.credit_card_outlined, 'Plano', '/app/plan'),
          _link(context, Icons.settings_outlined, 'Empresa', '/app/settings'),
                ],
              ),
            ),
          ),
          const Divider(color: Color(0xFF294A4C), height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFCBDBD7),
                side: const BorderSide(color: Color(0xFF486866)),
              ),
              onPressed: () async {
                await di<SessionStore>().logout();
                if (context.mounted) context.go('/');
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sair da conta'),
            ),
          ),
        ],
      );

  Widget _link(BuildContext context, IconData icon, String label, String path) {
    final selected = GoRouterState.of(context).uri.path == path;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 2),
      child: ListTile(
        dense: true,
        minLeadingWidth: 24,
        leading: Icon(
          icon,
          size: 21,
          color: selected ? CormexTheme.sage : const Color(0xFF9EB7B1),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFFC0D0CC),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        tileColor: selected ? const Color(0xFF235047) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        onTap: () {
          if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
            Navigator.pop(context);
          }
          context.go(path);
        },
      ),
    );
  }
}
