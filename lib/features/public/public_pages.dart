import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme.dart';
import '../../core/auth/session_store.dart';
import '../../core/config/app_config.dart';
import '../../core/di/registry.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

class FindPage extends StatefulWidget {
  const FindPage({super.key});
  @override
  State<FindPage> createState() => _FindPageState();
}

class _FindPageState extends State<FindPage> {
  final city = TextEditingController();
  late Future<Map<String, dynamic>> segments = di<ApiClient>().call(
    'segments-list',
  );
  late Future<Map<String, dynamic>> results = search();
  String? segment;
  final List<dynamic> accumulated = [];

  Future<Map<String, dynamic>> search([String? cursor]) =>
      di<ApiClient>().call('discovery-search', {
        if (segment != null) 'segmentCode': segment,
        if (city.text.trim().isNotEmpty) 'city': city.text.trim(),
        if (cursor != null) 'cursor': cursor,
      });
  void reload() => setState(() {
        accumulated.clear();
        results = search();
      });
  @override
  void dispose() {
    city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PublicFrame(
        child: SingleChildScrollView(
          child: PageWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const Text(
                  'ENCONTRE SERVIÇOS',
                  style: TextStyle(
                    color: CormexTheme.forest,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Encontre quem faz',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Escolha um segmento e procure por cidade. A localização do dispositivo não é necessária.',
                ),
                const SizedBox(height: 24),
                RemoteData(
                  future: segments,
                  retry: () => setState(
                    () => segments = di<ApiClient>().call('segments-list'),
                  ),
                  builder: (data) => Wrap(
                    spacing: 14,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 240,
                        child: DropdownButtonFormField<String>(
                          initialValue: segment ?? '',
                          decoration:
                              const InputDecoration(labelText: 'Segmento'),
                          items: [
                            const DropdownMenuItem(
                                value: '', child: Text('Todos')),
                            for (final s in data['items'] as List)
                              DropdownMenuItem(
                                value: s['code'].toString(),
                                child: Text(s['displayName'].toString()),
                              ),
                          ],
                          onChanged: (v) {
                            segment = v == '' ? null : v;
                            reload();
                          },
                        ),
                      ),
                      SizedBox(
                        width: 260,
                        child: TextField(
                          controller: city,
                          decoration: const InputDecoration(
                            labelText: 'Cidade',
                            hintText: 'Digite sua cidade',
                          ),
                          onSubmitted: (_) => reload(),
                        ),
                      ),
                      FilledButton(
                          onPressed: reload, child: const Text('Buscar')),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                RemoteData(
                  future: results,
                  retry: reload,
                  builder: (data) {
                    final items = [
                      ...accumulated,
                      ...((data['items'] as List?) ?? []),
                    ];
                    final cursor = data['nextCursor']?.toString();
                    if (items.isEmpty) {
                      return const Notice(
                        message:
                            'Nenhuma empresa pública encontrada. Experimente outra cidade ou segmento.',
                      );
                    }
                    return Column(
                      children: [
                        for (final item in items)
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
                                  Icons.storefront_outlined,
                                  color: CormexTheme.forest,
                                ),
                              ),
                              title: Text(item['name'].toString()),
                              subtitle: Text(
                                '${item['city']} • ${item['state']}\n${item['description']?.toString() ?? ''}',
                              ),
                              isThreeLine: true,
                              trailing: const Icon(Icons.arrow_forward),
                              onTap: () => context.go(
                                '/business/${item['slug']}',
                              ),
                            ),
                          ),
                        if (cursor != null)
                          TextButton(
                            onPressed: () => setState(() {
                              accumulated.clear();
                              accumulated.addAll(items);
                              results = search(cursor);
                            }),
                            child: const Text('Carregar mais'),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
}

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
                ? Notice(
                    message:
                        'Reserva confirmada. Protocolo: ${confirmed!['id']}',
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
