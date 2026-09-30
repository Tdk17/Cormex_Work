import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/auth/session_store.dart';
import '../../core/di/registry.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Future<Map<String, dynamic>> future = load();
  final name = TextEditingController();
  final description = TextEditingController();
  final address = TextEditingController();
  bool public = false, initialized = false, busy = false;
  String? error;
  Future<Map<String, dynamic>> load() => di<ApiClient>().call(
        'workspaces-get',
        {'workspaceId': di<SessionStore>().workspaceId.value},
      );
  @override
  void dispose() {
    name.dispose();
    description.dispose();
    address.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await di<ApiClient>().call('workspaces-update', {
        'workspaceId': di<SessionStore>().workspaceId.value,
        'name': name.text.trim(),
        'description': description.text.trim(),
        'address': address.text.trim(),
        'publicProfileEnabled': public,
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Perfil atualizado.')));
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PageWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'CONFIGURAÇÕES',
              style: TextStyle(
                color: CormexTheme.forest,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Text('Sua empresa',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 18),
            RemoteData(
              future: future,
              retry: () => setState(() {
                initialized = false;
                future = load();
              }),
              builder: (data) {
                if (!initialized) {
                  initialized = true;
                  name.text = data['name'].toString();
                  description.text = data['description']?.toString() ?? '';
                  address.text = data['address']?.toString() ?? '';
                  public = data['publicProfileEnabled'] == true;
                }
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: name,
                          decoration: const InputDecoration(labelText: 'Nome'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: description,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Descrição pública',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: address,
                          decoration: const InputDecoration(
                            labelText: 'Endereço do atendimento',
                            hintText: 'Rua, número e bairro',
                          ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          value: public,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Perfil público ativo'),
                          subtitle: const Text(
                            'Permite que clientes encontrem sua empresa pela cidade.',
                          ),
                          onChanged: (v) => setState(() => public = v),
                        ),
                        Text(
                          'Endereço público: /business/${data['slug']}',
                        ),
                        const SizedBox(height: 12),
                        if (error != null) Notice(message: error!),
                        Wrap(
                          spacing: 12,
                          children: [
                            FilledButton(
                              onPressed: busy ? null : save,
                              child: Text(
                                busy ? 'Salvando...' : 'Salvar alterações',
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.go(
                                '/business/${data['slug']}',
                              ),
                              child: const Text('Ver perfil'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
}
