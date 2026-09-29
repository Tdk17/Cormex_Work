import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/auth/session_store.dart';
import '../../core/di/registry.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

class HoursPage extends StatefulWidget {
  const HoursPage({super.key});
  @override
  State<HoursPage> createState() => _HoursPageState();
}

class _HoursPageState extends State<HoursPage> {
  static const labels = [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo',
  ];
  late Future<Map<String, dynamic>> future = di<ApiClient>().call(
    'business-hours-get',
    {'workspaceId': di<SessionStore>().workspaceId.value},
  );
  final enabled = List<bool>.filled(7, false);
  final starts = List.generate(7, (_) => TextEditingController(text: '09:00'));
  final ends = List.generate(7, (_) => TextEditingController(text: '18:00'));
  bool initialized = false, busy = false;
  String? error;
  @override
  void dispose() {
    for (final c in [...starts, ...ends]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await di<ApiClient>().call('business-hours-update', {
        'workspaceId': di<SessionStore>().workspaceId.value,
        'days': List.generate(
          7,
          (i) => {
            'weekday': i + 1,
            'intervals': enabled[i]
                ? [
                    {
                      'start': starts[i].text.trim(),
                      'end': ends[i].text.trim(),
                    },
                  ]
                : <Map<String, String>>[],
          },
        ),
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Horários salvos.')));
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
              'DISPONIBILIDADE',
              style: TextStyle(
                color: CormexTheme.forest,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Horário de funcionamento',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Configure um intervalo por dia. A API já suporta intervalos adicionais.',
            ),
            const SizedBox(height: 18),
            RemoteData(
              future: future,
              retry: () => setState(() {
                initialized = false;
                future = di<ApiClient>().call('business-hours-get', {
                  'workspaceId': di<SessionStore>().workspaceId.value,
                });
              }),
              builder: (data) {
                if (!initialized) {
                  initialized = true;
                  for (final item in data['items'] as List) {
                    final i = (item['weekday'] as int) - 1;
                    final intervals = item['intervals'] as List;
                    enabled[i] = intervals.isNotEmpty;
                    if (intervals.isNotEmpty) {
                      starts[i].text = intervals.first['start'].toString();
                      ends[i].text = intervals.first['end'].toString();
                    }
                  }
                }
                return Column(
                  children: [
                    for (var i = 0; i < 7; i++)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(labels[i]),
                                value: enabled[i],
                                onChanged: (v) =>
                                    setState(() => enabled[i] = v),
                              ),
                              if (enabled[i])
                                Row(
                                  children: [
                                    Expanded(
                                        child: TextField(
                                      controller: starts[i],
                                      decoration: const InputDecoration(
                                        labelText: 'Abre',
                                        hintText: '09:00',
                                      ),
                                    )),
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8),
                                      child: Text('até'),
                                    ),
                                    Expanded(
                                        child: TextField(
                                      controller: ends[i],
                                      decoration: const InputDecoration(
                                        labelText: 'Fecha',
                                        hintText: '18:00',
                                      ),
                                    )),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    if (error != null) Notice(message: error!),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: busy ? null : save,
                      child: Text(busy ? 'Salvando...' : 'Salvar horários'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );
}
