import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme.dart';
import '../../core/auth/session_store.dart';
import '../../core/di/registry.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) => PublicFrame(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: CormexTheme.navy,
                child: PageWidth(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 76),
                    child: Wrap(
                      spacing: 48,
                      runSpacing: 32,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: math.min(
                              540, MediaQuery.sizeOf(context).width - 44),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AGENDA, EQUIPE E SERVIÇOS EM UM SÓ LUGAR',
                                style: TextStyle(
                                  color: CormexTheme.gold,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Seu negócio trabalha melhor quando tudo se conecta.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  height: 1.12,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Organize atendimentos, ofereça horários reais aos clientes e acompanhe sua operação.',
                                style: TextStyle(
                                  color: Color(0xFFD9E1EE),
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 30),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  FilledButton(
                                    onPressed: () => context.go('/onboarding'),
                                    child: const Text('Começar como empresa'),
                                  ),
                                  OutlinedButton(
                                    onPressed: () => context.go('/find'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side:
                                          const BorderSide(color: Colors.white),
                                    ),
                                    child: const Text('Encontrar um serviço'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: math.min(
                              360, MediaQuery.sizeOf(context).width - 44),
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C2F4C),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.calendar_month,
                                color: CormexTheme.gold,
                                size: 42,
                              ),
                              SizedBox(height: 18),
                              Text(
                                'Uma agenda para o seu jeito de atender',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Lavação, oficina e beleza usam o mesmo núcleo, com serviços e horários definidos pela empresa.',
                                style: TextStyle(
                                  color: Color(0xFFD9E1EE),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              PageWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 34),
                    Text(
                      'Pronto para o trabalho de verdade',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 18,
                      runSpacing: 18,
                      children: const [
                        _Feature(
                          icon: Icons.schedule,
                          title: 'Horários claros',
                          body:
                              'Mostre disponibilidade calculada a partir da agenda cadastrada.',
                        ),
                        _Feature(
                          icon: Icons.storefront,
                          title: 'Sua vitrine',
                          body:
                              'Ative um perfil público com seus serviços e sua cidade.',
                        ),
                        _Feature(
                          icon: Icons.shield_outlined,
                          title: 'Cada empresa, seus dados',
                          body:
                              'Acesso por equipe e validação de permissões no servidor.',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title, body;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: math.min(320, MediaQuery.sizeOf(context).width - 44),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: CormexTheme.blue, size: 34),
                const SizedBox(height: 15),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(body),
              ],
            ),
          ),
        ),
      );
}

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
