import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme.dart';
import '../../core/auth/session_store.dart';
import '../../core/di/registry.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

class BusinessPage extends StatefulWidget {
  const BusinessPage({super.key, required this.slug});
  final String slug;
  @override
  State<BusinessPage> createState() => _BusinessPageState();
}

class _BusinessPageState extends State<BusinessPage> {
  late Future<Map<String, dynamic>> future = di<ApiClient>().call(
    'workspaces-public-profile',
    {'slug': widget.slug},
  );
  @override
  Widget build(BuildContext context) => PublicFrame(
        child: SingleChildScrollView(
          child: PageWidth(
            child: RemoteData(
              future: future,
              retry: () => setState(
                () =>
                    future = di<ApiClient>().call('workspaces-public-profile', {
                  'slug': widget.slug,
                }),
              ),
              builder: (data) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 18),
                  const Text(
                    'PERFIL DA EMPRESA',
                    style: TextStyle(
                      color: CormexTheme.forest,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 11),
                  Text(
                    data['name'].toString(),
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  Text('${data['city']} • ${data['state']}'),
                  const SizedBox(height: 12),
                  Text(data['description']?.toString() ?? ''),
                  const SizedBox(height: 28),
                  Text(
                    'Serviços',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  if ((data['services'] as List).isEmpty)
                    const Notice(
                      message: 'Esta empresa ainda não publicou serviços.',
                    ),
                  for (final service in data['services'] as List)
                    Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(18),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: CormexTheme.pale,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.design_services_outlined,
                            color: CormexTheme.forest,
                          ),
                        ),
                        title: Text(service['name'].toString()),
                        subtitle: Text(
                          '${service['durationMinutes']} min • ${service['pricingMode'] == 'quote' ? 'Sob consulta' : 'R\$ ${((service['priceAmount'] as num) / 100).toStringAsFixed(2)}'}',
                        ),
                        trailing: FilledButton(
                          onPressed: () => context.go(
                            '/book/${data['id']}/${service['id']}',
                          ),
                          child: const Text('Agendar'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}

class BookPage extends StatefulWidget {
  const BookPage({
    super.key,
    required this.workspaceId,
    required this.serviceId,
  });
  final String workspaceId, serviceId;
  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  DateTime day = DateTime.now();
  String? selected;
  bool busy = false;
  String? error;
  Map<String, dynamic>? confirmed;
  final key = const Uuid().v4();
  late Future<Map<String, dynamic>> slots = fetch();

  Future<Map<String, dynamic>> fetch() =>
      di<ApiClient>().call('availability-search', {
        'workspaceId': widget.workspaceId,
        'serviceId': widget.serviceId,
        'day': DateFormat('yyyy-MM-dd').format(day),
      });
  void changeDate(DateTime value) => setState(() {
        day = value;
        selected = null;
        slots = fetch();
      });
  Future<void> confirm() async {
    if (selected == null) return;
    if (!di<SessionStore>().isAuthenticated) {
      context.go(
        '/login?from=${Uri.encodeComponent(
          '/book/${widget.workspaceId}/${widget.serviceId}',
        )}',
      );
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final data = await di<ApiClient>().call('bookings-create', {
        'workspaceId': widget.workspaceId,
        'serviceId': widget.serviceId,
        'startAt': selected,
        'idempotencyKey': key,
      });
      if (mounted) setState(() => confirmed = data);
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          slots = fetch();
          selected = null;
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PublicFrame(
        child: SingleChildScrollView(
          child: PageWidth(
            maxWidth: 760,
            child: confirmed != null
                ? Column(
                    children: [
                      Notice(
                        message:
                            'Reserva registrada. Protocolo: ${confirmed!['id']}',
                      ),
                      TextButton(
                        onPressed: () => context.go('/my-bookings'),
                        child: const Text('Ver meus agendamentos'),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'Escolha seu horário',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'A disponibilidade será verificada novamente ao confirmar.',
                      ),
                      const SizedBox(height: 22),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(DateFormat('dd/MM/yyyy').format(day)),
                        onPressed: () async {
                          final chosen = await showDatePicker(
                            context: context,
                            initialDate: day,
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 90)),
                          );
                          if (chosen != null) changeDate(chosen);
                        },
                      ),
                      const SizedBox(height: 20),
                      RemoteData(
                        future: slots,
                        retry: () => setState(() => slots = fetch()),
                        builder: (data) => (data['slots'] as List).isEmpty
                            ? const Notice(
                                message: 'Sem horários disponíveis nesta data.',
                              )
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final slot in data['slots'] as List)
                                    ChoiceChip(
                                      label: Text(slot['localTime'].toString()),
                                      selected: selected == slot['startAt'],
                                      onSelected: (_) => setState(
                                        () => selected =
                                            slot['startAt'].toString(),
                                      ),
                                    ),
                                ],
                              ),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: busy || selected == null ? null : confirm,
                        child:
                            Text(busy ? 'Confirmando...' : 'Confirmar reserva'),
                      ),
                    ],
                  ),
          ),
        ),
      );
}
