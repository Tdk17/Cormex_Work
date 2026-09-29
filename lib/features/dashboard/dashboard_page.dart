import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/auth/session_store.dart';
import '../../core/di/registry.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<Map<String, dynamic>> future = load();
  Future<Map<String, dynamic>> load() async {
    final id = di<SessionStore>().workspaceId.value!;
    final results = await Future.wait([
      di<ApiClient>().call('dashboard-summary', {'workspaceId': id}),
      di<ApiClient>().call('subscription-status', {'workspaceId': id}),
    ]);
    return {'summary': results[0], 'subscription': results[1]};
  }

  @override
  Widget build(BuildContext context) => PageWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [CormexTheme.deep, CormexTheme.petroleum],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VISÃO GERAL',
                    style: TextStyle(
                      color: CormexTheme.sage,
                      fontSize: 11,
                      letterSpacing: 1.7,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 11),
                  Text(
                    'Sua operação em foco.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Acompanhe reservas e atividades com dados do servidor.',
                    style: TextStyle(color: Color(0xFFC5D6D2)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            RemoteData(
              future: future,
              retry: () => setState(() => future = load()),
              builder: (data) {
                final summary = data['summary'] as Map;
                final subscription = data['subscription'] as Map;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (subscription['status'] != 'active')
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Plano: ${subscription['status']}${subscription['trialEnd'] == null ? '' : ' • avaliação até ${subscription['trialEnd']}'}',
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.go('/app/plan'),
                                child: const Text('Ver plano'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        _Metric(
                          label: 'Reservas do dia',
                          value: summary['total'].toString(),
                          icon: Icons.calendar_today_outlined,
                        ),
                        _Metric(
                          label: 'Confirmadas',
                          value: (summary['byStatus']?['confirmed'] ?? 0)
                              .toString(),
                          icon: Icons.check_circle_outline_rounded,
                        ),
                        _Metric(
                          label: 'Canceladas',
                          value: ((summary['byStatus']
                                          ?['canceled_by_customer'] ??
                                      0) +
                                  (summary['byStatus']
                                          ?['canceled_by_business'] ??
                                      0))
                              .toString(),
                          icon: Icons.event_busy_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Próximos atendimentos',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    if ((summary['upcoming'] as List).isEmpty)
                      const Notice(
                        message:
                            'Sem reservas próximas. Configure horários e publique um serviço para começar.',
                      ),
                    for (final booking in summary['upcoming'] as List)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.event_available),
                          title: Text(
                            booking['serviceName']?.toString() ?? 'Serviço',
                          ),
                          subtitle: Text(booking['startAt'].toString()),
                          trailing: Text(booking['status'].toString()),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: MediaQuery.sizeOf(context).width < 600
            ? MediaQuery.sizeOf(context).width - 36
            : 235,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(color: CormexTheme.muted),
                      ),
                    ),
                    Icon(icon, size: 21, color: CormexTheme.forest),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
          ),
        ),
      );
}
