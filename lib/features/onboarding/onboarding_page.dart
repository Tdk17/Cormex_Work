import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme.dart';
import '../../core/auth/session_store.dart';
import '../../core/di/registry.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final slug = TextEditingController();
  final city = TextEditingController();
  final state = TextEditingController();
  final timezone = TextEditingController(text: 'America/Sao_Paulo');
  final idempotencyKey = const Uuid().v4();
  String? segment;
  String? error;
  bool busy = false;
  late Future<Map<String, dynamic>> future = di<ApiClient>().call(
    'segments-list',
  );

  @override
  void dispose() {
    name.dispose();
    slug.dispose();
    city.dispose();
    state.dispose();
    timezone.dispose();
    super.dispose();
  }

  Future<void> create() async {
    if (!form.currentState!.validate() || segment == null) {
      setState(() => error = 'Escolha um segmento e confira os campos.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await di<ApiClient>().call('workspaces-create', {
        'name': name.text.trim(),
        'slug': slug.text.trim().toLowerCase(),
        'city': city.text.trim(),
        'state': state.text.trim(),
        'timezone': timezone.text.trim(),
        'segmentCode': segment,
        'idempotencyKey': idempotencyKey,
      });
      await di<SessionStore>().refresh();
      if (mounted) context.go('/app/plan');
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PublicFrame(
        child: SingleChildScrollView(
          child: PageWidth(
            maxWidth: 740,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18),
                const Text(
                  'CONFIGURAÇÃO INICIAL',
                  style: TextStyle(
                    color: CormexTheme.forest,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sua empresa no Cormex Work',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cadastre a operação. Os segmentos são carregados do Back4App.',
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: name,
                            decoration: const InputDecoration(
                              labelText: 'Nome da empresa',
                            ),
                            validator: requiredField,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: slug,
                            decoration: const InputDecoration(
                              labelText: 'Endereço público',
                              hintText: 'minha-empresa',
                            ),
                            validator: (v) => RegExp(
                                        r'^[a-z0-9]+(?:-[a-z0-9]+)*$')
                                    .hasMatch(v ?? '')
                                ? null
                                : 'Use letras minúsculas, números e hífens.',
                          ),
                          const SizedBox(height: 12),
                          RemoteData(
                            future: future,
                            retry: () => setState(
                              () => future =
                                  di<ApiClient>().call('segments-list'),
                            ),
                            builder: (data) => DropdownButtonFormField<String>(
                              initialValue: segment,
                              decoration: const InputDecoration(
                                labelText: 'Segmento',
                              ),
                              items: [
                                for (final item in data['items'] as List)
                                  DropdownMenuItem(
                                    value: item['code'].toString(),
                                    child: Text(item['displayName'].toString()),
                                  ),
                              ],
                              onChanged: (v) => setState(() => segment = v),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: 310,
                                child: TextFormField(
                                  controller: city,
                                  decoration: const InputDecoration(
                                    labelText: 'Cidade',
                                  ),
                                  validator: requiredField,
                                ),
                              ),
                              SizedBox(
                                width: 190,
                                child: TextFormField(
                                  controller: state,
                                  decoration: const InputDecoration(
                                    labelText: 'Estado',
                                  ),
                                  validator: requiredField,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: timezone,
                            decoration: const InputDecoration(
                              labelText: 'Fuso horário IANA',
                            ),
                            validator: requiredField,
                          ),
                          if (error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: busy ? null : create,
                            child: Text(
                              busy
                                  ? 'Criando...'
                                  : 'Criar empresa e escolher plano',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

String? requiredField(String? value) =>
    value == null || value.trim().isEmpty ? 'Campo obrigatório.' : null;

class PlanPage extends StatefulWidget {
  const PlanPage({super.key});
  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  String? error;
  bool busy = false;
  late Future<Map<String, dynamic>> future = load();
  Future<Map<String, dynamic>> load() async {
    final id = di<SessionStore>().workspaceId.value;
    final w = await di<ApiClient>().call('workspaces-get', {'workspaceId': id});
    final plans = await di<ApiClient>().call('plans-list', {
      'segmentCode': w['segmentCode'],
    });
    return plans;
  }

  Future<void> select(Map plan) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await di<ApiClient>().call('subscription-select-trial', {
        'workspaceId': di<SessionStore>().workspaceId.value,
        'planCode': plan['code'],
        'acceptedVersion': plan['version'],
      });
      if (mounted) context.go('/app/dashboard');
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
              'SEU ACESSO',
              style: TextStyle(
                color: CormexTheme.forest,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Escolha seu plano',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'O acesso de avaliação começa após sua escolha, se o plano oferecer esse período. '
              'A cobrança não estará disponível até configurar um provedor.',
            ),
            const SizedBox(height: 18),
            if (error != null) Notice(message: error!),
            RemoteData(
              future: future,
              retry: () => setState(() => future = load()),
              builder: (data) {
                final plans = data['items'] as List;
                if (plans.isEmpty) {
                  return const Notice(
                    message:
                        'Ainda não há planos disponíveis para este segmento.',
                  );
                }
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final plan in plans)
                      SizedBox(
                        width: 290,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: CormexTheme.pale,
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: const Icon(
                                    Icons.layers_outlined,
                                    color: CormexTheme.forest,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                Text(
                                  plan['name'].toString(),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'R\$ ${((plan['amount'] as num) / 100).toStringAsFixed(2)} / ${plan['billingInterval']}',
                                ),
                                Text(
                                  '${plan['trialDays']} dias de avaliação',
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Até ${plan['limits']?['services'] ?? 0} serviços',
                                ),
                                const SizedBox(height: 16),
                                FilledButton(
                                  onPressed:
                                      busy || (plan['trialDays'] as num) <= 0
                                          ? null
                                          : () => select(plan),
                                  child: const Text('Iniciar avaliação'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      );
}
