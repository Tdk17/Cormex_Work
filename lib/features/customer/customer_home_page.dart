import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/auth/session_store.dart';
import '../../core/di/registry.dart';
import '../../core/location/location_picker.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  final city = TextEditingController();
  String? selectedState;
  String? locationError;
  late Future<Map<String, dynamic>> segments =
      di<ApiClient>().call('segments-list');
  late Future<Map<String, dynamic>> bookings =
      di<ApiClient>().call('bookings-mine');
  late Future<Map<String, dynamic>> notifications =
      di<ApiClient>().call('notifications-list', {'limit': 10});

  Future<void> markRead(Map item) async {
    try {
      await di<ApiClient>().call('notifications-mark-read',
          {'notificationId': item['id']});
      if (mounted) {
        setState(() => notifications =
            di<ApiClient>().call('notifications-list', {'limit': 10}));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    city.text = di<SessionStore>().user.value?['city']?.toString() ?? '';
    selectedState = di<SessionStore>().user.value?['state']?.toString();
  }

  @override
  void dispose() {
    city.dispose();
    super.dispose();
  }

  void openSearch([String? segment]) {
    context.go(Uri(
      path: '/find',
      queryParameters: {
        if (segment != null) 'segment': segment,
        if (city.text.trim().isNotEmpty) 'city': city.text.trim(),
        if (selectedState != null && selectedState!.isNotEmpty)
          'state': selectedState!,
      },
    ).toString());
  }

  @override
  Widget build(BuildContext context) => PublicFrame(
        child: SingleChildScrollView(
          child: PageWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text('Seu espaço de serviços',
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 8),
                const Text(
                  'Escolha uma categoria, encontre um profissional e acompanhe seus agendamentos.',
                  style: TextStyle(color: CormexTheme.muted),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sua cidade',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        const Text(
                          'Selecione sua cidade. Ela ficará salva na sua conta para as próximas visitas.',
                          style: TextStyle(color: CormexTheme.muted),
                        ),
                        const SizedBox(height: 12),
                        LocationPicker(
                          initialState: selectedState,
                          initialCity: city.text,
                          onChanged: (state, name, id) async {
                            try {
                              await di<ApiClient>().call('customer-profile-update', {
                                'city': name, 'state': state, 'municipalityId': id,
                              });
                              await di<SessionStore>().refresh();
                              if (mounted) {
                                setState(() {
                                  city.text = name;
                                  selectedState = state;
                                  locationError = null;
                                });
                              }
                            } catch (error) {
                              if (mounted) setState(() => locationError = error.toString());
                            }
                          },
                        ),
                        if (locationError != null)
                          Text(locationError!, style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text('O que você precisa?',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 14),
                RemoteData(
                  future: segments,
                  retry: () => setState(
                    () => segments = di<ApiClient>().call('segments-list'),
                  ),
                  builder: (data) {
                    final items = data['items'] as List? ?? [];
                    if (items.isEmpty) {
                      return const Notice(
                        message: 'Ainda não há categorias disponíveis.',
                      );
                    }
                    return LayoutBuilder(
                      builder: (context, constraints) => Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          for (final item in items)
                            SizedBox(
                              width: constraints.maxWidth < 630
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth - 28) / 3,
                              child: Card(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => openSearch(item['code'].toString()),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.design_services_outlined,
                                            color: CormexTheme.forest),
                                        const SizedBox(height: 16),
                                        Text(item['displayName'].toString(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium),
                                        const SizedBox(height: 8),
                                        const Text('Ver profissionais',
                                            style: TextStyle(
                                                color: CormexTheme.forest)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: Text('Seus agendamentos',
                          style: Theme.of(context).textTheme.headlineMedium),
                    ),
                    TextButton(
                      onPressed: () => context.go('/my-bookings'),
                      child: const Text('Ver todos'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                RemoteData(
                  future: bookings,
                  retry: () => setState(
                    () => bookings = di<ApiClient>().call('bookings-mine'),
                  ),
                  builder: (data) {
                    final items = data['items'] as List? ?? [];
                    if (items.isEmpty) {
                      return const Notice(
                        message: 'Você ainda não tem agendamentos.',
                      );
                    }
                    return Column(
                      children: [
                        for (final booking in items.take(3))
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.event_available_outlined,
                                  color: CormexTheme.forest),
                              title: Text(booking['serviceName']?.toString() ??
                                  'Atendimento'),
                              subtitle: Text(
                                '${booking['workspaceName'] ?? 'Empresa'} • '
                                '${booking['localStart'] ?? booking['startAt']}\n'
                                '${booking['address'] ?? ''}, ${booking['city'] ?? ''} / ${booking['state'] ?? ''}',
                              ),
                              trailing: Text(booking['status']?.toString() ?? ''),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 30),
                Text('Atualizações dos atendimentos',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 12),
                RemoteData(
                  future: notifications,
                  retry: () => setState(() => notifications =
                      di<ApiClient>().call('notifications-list', {'limit': 10})),
                  builder: (data) {
                    final items = data['items'] as List? ?? [];
                    if (items.isEmpty) {
                      return const Notice(message: 'Nenhuma atualização por enquanto.');
                    }
                    return Column(children: [
                      for (final item in items)
                        Card(child: ListTile(
                          leading: Icon(item['readAt'] == null
                              ? Icons.notifications_active_outlined
                              : Icons.notifications_none_outlined,
                            color: CormexTheme.forest),
                          title: Text(item['eventType'].toString().replaceAll('_', ' ')),
                          subtitle: Text('Atendimento ${item['minimalPayload']?['bookingId'] ?? ''}'),
                          trailing: item['readAt'] == null
                              ? TextButton(onPressed: () => markRead(item),
                                  child: const Text('Marcar como lida'))
                              : null,
                          onTap: item['minimalPayload']?['orderId'] != null
                              ? () => context.go('/orders/${item['minimalPayload']['orderId']}')
                              : () => context.go('/my-bookings'),
                        )),
                    ]);
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      );
}
