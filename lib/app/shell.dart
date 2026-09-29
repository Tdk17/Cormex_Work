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
    final wide = MediaQuery.sizeOf(context).width > 850;
    final menu = _menu(context);
    return Scaffold(
      appBar: wide ? null : AppBar(title: const Brand()),
      drawer: wide ? null : Drawer(child: SafeArea(child: menu)),
      body: Row(
        children: [
          if (wide)
            Container(
              width: 244,
              color: CormexTheme.navy,
              child: SafeArea(child: menu),
            ),
          Expanded(child: SingleChildScrollView(child: child)),
        ],
      ),
    );
  }

  Widget _menu(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(padding: EdgeInsets.all(22), child: Brand(light: true)),
          const Divider(color: Color(0xFF40516A)),
          _link(
            context,
            Icons.space_dashboard_outlined,
            'Visão geral',
            '/app/dashboard',
          ),
          _link(
            context,
            Icons.design_services_outlined,
            'Serviços',
            '/app/services',
          ),
          _link(
            context,
            Icons.calendar_month_outlined,
            'Reservas',
            '/app/bookings',
          ),
          _link(context, Icons.access_time, 'Horários', '/app/hours'),
          _link(context, Icons.credit_card, 'Plano', '/app/plan'),
          _link(context, Icons.settings_outlined, 'Empresa', '/app/settings'),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(14),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF7B8CA4)),
              ),
              onPressed: () async {
                await di<SessionStore>().logout();
                if (context.mounted) context.go('/');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sair'),
            ),
          ),
        ],
      );

  Widget _link(BuildContext context, IconData icon, String label, String path) {
    final selected = GoRouterState.of(context).uri.path == path;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: selected ? CormexTheme.gold : Colors.white70,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        tileColor: selected ? const Color(0xFF263C5D) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
