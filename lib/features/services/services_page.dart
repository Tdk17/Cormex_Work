import 'package:flutter/material.dart';

import '../../core/auth/session_store.dart';
import '../../core/di/registry.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});
  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  late Future<Map<String, dynamic>> future = load();
  Future<Map<String, dynamic>> load() => di<ApiClient>().call('services-list', {
        'workspaceId': di<SessionStore>().workspaceId.value,
      });
  void reload() => setState(() => future = load());
  Future<void> archive(Map service) async {
    try {
      await di<ApiClient>().call('services-archive', {
        'workspaceId': di<SessionStore>().workspaceId.value,
        'serviceId': service['id'],
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
            Wrap(
              spacing: 20,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Serviços',
                    style: Theme.of(context).textTheme.headlineMedium),
                FilledButton.icon(
                  onPressed: () async {
                    final created = await showDialog<bool>(
                      context: context,
                      builder: (_) => const _ServiceDialog(),
                    );
                    if (created == true) reload();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Novo serviço'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            RemoteData(
              future: future,
              retry: reload,
              builder: (data) {
                final services = data['items'] as List;
                if (services.isEmpty) {
                  return const Notice(
                    message:
                        'Cadastre o primeiro serviço para começar a receber reservas.',
                  );
                }
                return Column(
                  children: [
                    for (final service in services)
                      Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(18),
                          title: Text(service['name'].toString()),
                          subtitle: Text(
                            '${service['durationMinutes']} min • ${service['pricingMode'] == 'quote' ? 'Sob consulta' : 'R\$ ${((service['priceAmount'] as num) / 100).toStringAsFixed(2)}'}',
                          ),
                          trailing: IconButton(
                            tooltip: 'Arquivar',
                            icon: const Icon(Icons.archive_outlined),
                            onPressed: () => archive(service),
                          ),
                        ),
                      ),
                    if (data['nextCursor'] != null)
                      const Notice(
                        message:
                            'Há mais serviços. A paginação da lista será adicionada na próxima etapa.',
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      );
}

class _ServiceDialog extends StatefulWidget {
  const _ServiceDialog();
  @override
  State<_ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<_ServiceDialog> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final duration = TextEditingController(text: '60');
  final price = TextEditingController();
  bool quote = false, busy = false;
  String? error;
  @override
  void dispose() {
    name.dispose();
    duration.dispose();
    price.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final cents = quote
          ? null
          : (double.parse(price.text.trim().replaceAll(',', '.')) * 100)
              .round();
      await di<ApiClient>().call('services-create', {
        'workspaceId': di<SessionStore>().workspaceId.value,
        'name': name.text.trim(),
        'durationMinutes': int.parse(duration.text.trim()),
        'bufferAfterMinutes': 0,
        'pricingMode': quote ? 'quote' : 'fixed',
        if (cents != null) 'priceAmount': cents,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Novo serviço'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: form,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nome'),
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? 'Informe o nome.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: duration,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Duração em minutos',
                    ),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      return n == null || n < 15 || n > 480
                          ? 'Entre 15 e 480 minutos.'
                          : null;
                    },
                  ),
                  SwitchListTile(
                    value: quote,
                    title: const Text('Preço sob consulta'),
                    onChanged: (v) => setState(() => quote = v),
                  ),
                  if (!quote)
                    TextFormField(
                      controller: price,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Preço em R\$'),
                      validator: (v) {
                        final n =
                            double.tryParse((v ?? '').replaceAll(',', '.'));
                        return n == null || n < 0
                            ? 'Informe um preço válido.'
                            : null;
                      },
                    ),
                  if (error != null)
                    Text(
                      error!,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: busy ? null : save,
            child: Text(busy ? 'Salvando...' : 'Salvar'),
          ),
        ],
      );
}
