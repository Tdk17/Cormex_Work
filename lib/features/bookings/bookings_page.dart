import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/auth/session_store.dart';
import '../../core/di/registry.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});
  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  late Future<Map<String, dynamic>> future = load();
  Future<Map<String, dynamic>> load() => di<ApiClient>().call('bookings-list', {
        'workspaceId': di<SessionStore>().workspaceId.value,
      });
  void reload() => setState(() => future = load());
  Future<void> transition(Map booking, String status) async {
    try {
      await di<ApiClient>().call('bookings-transition', {
        'workspaceId': di<SessionStore>().workspaceId.value,
        'bookingId': booking['id'],
        'status': status,
      });
      reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) => PageWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'AGENDA',
              style: TextStyle(
                color: CormexTheme.forest,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Text('Reservas', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 18),
            RemoteData(
              future: future,
              retry: reload,
              builder: (data) {
                final items = data['items'] as List;
                if (items.isEmpty) {
                  return const Notice(
                    message:
                        'Nenhuma reserva por enquanto. Seus próximos atendimentos aparecerão aqui.',
                  );
                }
                return Column(
                  children: [
                    for (final booking in items)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: CormexTheme.pale,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.event_available_outlined,
                                  color: CormexTheme.forest,
                                ),
                              ),
                              SizedBox(
                                width: 270,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      booking['serviceName']?.toString() ??
                                          'Serviço',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    Text(
                                      DateFormat('dd/MM/yyyy HH:mm').format(
                                        DateTime.parse(
                                          booking['startAt'].toString(),
                                        ).toLocal(),
                                      ),
                                    ),
                                    Text('Protocolo: ${booking['id']}'),
                                  ],
                                ),
                              ),
                              Chip(label: Text(booking['status'].toString())),
                              if (booking['status'] == 'pending')
                                TextButton(
                                  onPressed: () =>
                                      transition(booking, 'confirmed'),
                                  child: const Text('Confirmar'),
                                ),
                              if (booking['status'] == 'confirmed')
                                TextButton(
                                  onPressed: () =>
                                      transition(booking, 'completed'),
                                  child: const Text('Concluir'),
                                ),
                              if ([
                                'pending',
                                'confirmed',
                              ].contains(booking['status']))
                                TextButton(
                                  onPressed: () => transition(
                                      booking, 'canceled_by_business'),
                                  child: const Text('Cancelar'),
                                ),
                            ],
                          ),
                        ),
                      ),
                    if (data['nextCursor'] != null)
                      const Notice(
                        message:
                            'Há mais reservas. A paginação será adicionada na próxima etapa.',
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      );
}

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});
  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  late Future<Map<String, dynamic>> future =
      di<ApiClient>().call('bookings-mine');
  void reload() =>
      setState(() => future = di<ApiClient>().call('bookings-mine'));

  Future<void> cancel(Map booking) async {
    try {
      await di<ApiClient>().call('bookings-transition', {
        'workspaceId': booking['workspaceId'],
        'bookingId': booking['id'],
        'status': 'canceled_by_customer',
      });
      reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) => PublicFrame(
        child: SingleChildScrollView(
          child: PageWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text('Minhas reservas',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 18),
                RemoteData(
                  future: future,
                  retry: reload,
                  builder: (data) {
                    final items = data['items'] as List;
                    if (items.isEmpty) {
                      return Column(children: [
                        const Notice(message: 'Você ainda não tem reservas.'),
                        TextButton(
                            onPressed: () => context.go('/client'),
                            child: const Text('Encontrar serviço')),
                      ]);
                    }
                    return Column(children: [
                      for (final booking in items)
                        Card(
                            child: ListTile(
                          contentPadding: const EdgeInsets.all(18),
                          title: Text(
                              booking['serviceName']?.toString() ?? 'Serviço'),
                          subtitle: Text(
                              '${booking['startAt']}\nProtocolo: ${booking['id']}'),
                          isThreeLine: true,
                          trailing: ['pending', 'confirmed']
                                  .contains(booking['status'])
                              ? TextButton(
                                  onPressed: () => cancel(booking),
                                  child: const Text('Cancelar'))
                              : Chip(label: Text(booking['status'].toString())),
                        )),
                    ]);
                  },
                ),
              ],
            ),
          ),
        ),
      );
}
