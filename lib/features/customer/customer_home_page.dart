import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/auth/session_store.dart';
import '../../core/di/registry.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  final city = TextEditingController();
  late Future<Map<String, dynamic>> segments =
      di<ApiClient>().call('segments-list');
  late Future<Map<String, dynamic>> bookings =
      di<ApiClient>().call('bookings-mine');

  @override
  void initState() {
    super.initState();
    city.text = di<SessionStore>().user.value?['city']?.toString() ?? '';
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
                          'Informe a cidade para encontrar atendimentos na sua região.',
                          style: TextStyle(color: CormexTheme.muted),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: city,
                          textInputAction: TextInputAction.search,
                          decoration: const InputDecoration(
                            labelText: 'Cidade',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                          onSubmitted: (_) => openSearch(),
                        ),
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
                                '${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(booking['startAt'].toString()).toLocal())}',
                              ),
                              trailing: Text(booking['status']?.toString() ?? ''),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      );
}
