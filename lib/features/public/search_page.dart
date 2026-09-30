import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/di/registry.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

class FindPage extends StatefulWidget {
  const FindPage({super.key, this.segmentCode, this.initialCity});
  final String? segmentCode;
  final String? initialCity;

  @override
  State<FindPage> createState() => _FindPageState();
}

class _FindPageState extends State<FindPage> {
  final city = TextEditingController();
  late Future<Map<String, dynamic>> segments =
      di<ApiClient>().call('segments-list');
  late Future<Map<String, dynamic>> results;
  String? segment;
  final List<dynamic> accumulated = [];

  @override
  void initState() {
    super.initState();
    segment = widget.segmentCode;
    city.text = widget.initialCity ?? '';
    results = search();
  }

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
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [CormexTheme.deep, CormexTheme.petroleum],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: PageWidth(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 35),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SUA REDE DE PROFISSIONAIS',
                          style: TextStyle(
                            color: CormexTheme.sage,
                            fontSize: 11,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Encontre o serviço certo.',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Explore profissionais por segmento e cidade. '
                          'Escolha com tranquilidade e reserve no horário disponível.',
                          style: TextStyle(
                            color: Color(0xFFC6D7D3),
                            fontSize: 16,
                            height: 1.5,
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
                    const SizedBox(height: 12),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(26),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'O que você procura?',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Filtre as empresas e encontre um atendimento perto de você.',
                              style: TextStyle(color: CormexTheme.muted),
                            ),
                            const SizedBox(height: 22),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final compact = constraints.maxWidth < 680;
                                final fieldWidth = compact
                                    ? constraints.maxWidth
                                    : (constraints.maxWidth - 30) / 2;
                                return Wrap(
                                  spacing: 14,
                                  runSpacing: 14,
                                  crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: fieldWidth,
                                      child: FutureBuilder<Map<String, dynamic>>(
                                        future: segments,
                                        builder: (context, snapshot) {
                                          final items = snapshot.data?['items']
                                                  as List? ??
                                              const [];
                                          final selected = items.any(
                                            (item) =>
                                                item['code'].toString() ==
                                                segment,
                                          )
                                              ? segment
                                              : '';
                                          return DropdownButtonFormField<String>(
                                            initialValue: selected,
                                            isExpanded: true,
                                            decoration: const InputDecoration(
                                              labelText: 'Segmento',
                                              prefixIcon: Icon(
                                                Icons.category_outlined,
                                              ),
                                            ),
                                            items: [
                                              const DropdownMenuItem(
                                                value: '',
                                                child: Text('Todos os segmentos'),
                                              ),
                                              for (final item in items)
                                                DropdownMenuItem(
                                                  value: item['code'].toString(),
                                                  child: Text(
                                                    item['displayName']
                                                        .toString(),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                            ],
                                            onChanged: (value) {
                                              segment = value == ''
                                                  ? null
                                                  : value;
                                              reload();
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                    SizedBox(
                                      width: fieldWidth,
                                      child: TextField(
                                        controller: city,
                                        textInputAction: TextInputAction.search,
                                        decoration: const InputDecoration(
                                          labelText: 'Cidade',
                                          hintText: 'Digite sua cidade',
                                          prefixIcon: Icon(
                                            Icons.location_on_outlined,
                                          ),
                                        ),
                                        onSubmitted: (_) => reload(),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            FutureBuilder<Map<String, dynamic>>(
                              future: segments,
                              builder: (context, snapshot) =>
                                  snapshot.hasError
                                      ? Padding(
                                          padding:
                                              const EdgeInsets.only(top: 12),
                                          child: TextButton.icon(
                                            onPressed: () => setState(
                                              () => segments = di<ApiClient>()
                                                  .call('segments-list'),
                                            ),
                                            icon: const Icon(Icons.refresh,
                                                size: 18),
                                            label: const Text(
                                              'Segmentos indisponíveis. Tentar novamente',
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: reload,
                              icon: const Icon(Icons.search_rounded),
                              label: const Text('Buscar empresas'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 38),
                    Text(
                      'Empresas para você',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Escolha um profissional para ver os serviços e horários.',
                      style: TextStyle(color: CormexTheme.muted),
                    ),
                    const SizedBox(height: 18),
                    FutureBuilder<Map<String, dynamic>>(
                      future: results,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState !=
                            ConnectionState.done) {
                          return const SizedBox(
                            height: 180,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (snapshot.hasError) {
                          return _SearchFeedback(
                            icon: Icons.wifi_off_rounded,
                            title: 'Não foi possível carregar as empresas',
                            message: snapshot.error.toString(),
                            action: 'Tentar novamente',
                            onPressed: reload,
                          );
                        }
                        final data = snapshot.data!;
                        final items = [
                          ...accumulated,
                          ...((data['items'] as List?) ?? []),
                        ];
                        final cursor = data['nextCursor']?.toString();
                        if (items.isEmpty) {
                          return _SearchFeedback(
                            icon: Icons.search_off_rounded,
                            title: 'Nenhuma empresa encontrada',
                            message: 'Experimente outra cidade ou segmento.',
                            action: 'Limpar filtros',
                            onPressed: () {
                              city.clear();
                              segment = null;
                              reload();
                            },
                          );
                        }
                        return Column(
                          children: [
                            for (final item in items)
                              Card(
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(20),
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: CormexTheme.pale,
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: const Icon(
                                      Icons.storefront_outlined,
                                      color: CormexTheme.forest,
                                    ),
                                  ),
                                  title: Text(
                                    item['name'].toString(),
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  subtitle: Text(
                                    '${item['city']} • ${item['state']}\n'
                                    '${item['description']?.toString() ?? ''}',
                                  ),
                                  isThreeLine: true,
                                  trailing:
                                      const Icon(Icons.arrow_forward_rounded),
                                  onTap: () => context.go(
                                    '/business/${item['slug']}',
                                  ),
                                ),
                              ),
                            if (cursor != null)
                              Padding(
                                padding: const EdgeInsets.all(15),
                                child: OutlinedButton(
                                  onPressed: () => setState(() {
                                    accumulated
                                      ..clear()
                                      ..addAll(items);
                                    results = search(cursor);
                                  }),
                                  child: const Text('Carregar mais empresas'),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _SearchFeedback extends StatelessWidget {
  const _SearchFeedback({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
    required this.onPressed,
  });

  final IconData icon;
  final String title, message, action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(34),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: CormexTheme.border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: CormexTheme.pale,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: CormexTheme.forest, size: 27),
            ),
            const SizedBox(height: 17),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: CormexTheme.muted),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: onPressed,
              child: Text(action),
            ),
          ],
        ),
      );
}
