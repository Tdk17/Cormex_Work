import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme.dart';
import '../../core/auth/session_store.dart';
import '../../core/di/registry.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});
  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  final now = DateTime.now();
  late String month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  late Future<Map<String, dynamic>> entries = load('finance-entries-list');
  late Future<Map<String, dynamic>> summary = load('finance-summary');
  String? error;
  String get workspaceId => di<SessionStore>().workspaceId.value!;
  Future<Map<String, dynamic>> load(String endpoint) =>
      di<ApiClient>().call(endpoint, {'workspaceId': workspaceId, 'month': month});
  void refresh() => setState(() {
    entries = load('finance-entries-list');
    summary = load('finance-summary');
  });
  String money(dynamic cents) =>
      'R\$ ${((cents as num? ?? 0) / 100).toStringAsFixed(2)}';

  Future<void> add() async {
    final description = TextEditingController();
    final amount = TextEditingController();
    String direction = 'income';
    DateTime dueAt = DateTime.now();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, change) => AlertDialog(
          title: const Text('Novo lançamento'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: description,
              decoration: const InputDecoration(labelText: 'Descrição')),
            TextField(controller: amount, keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Valor em reais', hintText: '150,00')),
            DropdownButtonFormField<String>(
              initialValue: direction,
              items: const [
                DropdownMenuItem(value: 'income', child: Text('Receita')),
                DropdownMenuItem(value: 'expense', child: Text('Despesa')),
              ],
              onChanged: (v) => change(() => direction = v ?? 'income'),
            ),
            TextButton.icon(
              onPressed: () async {
                final date = await showDatePicker(context: dialogContext,
                  initialDate: dueAt, firstDate: DateTime(2020),
                  lastDate: DateTime(2100));
                if (date != null) change(() => dueAt = date);
              },
              icon: const Icon(Icons.event_outlined),
              label: Text('Vencimento: ${dueAt.day}/${dueAt.month}/${dueAt.year}'),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Voltar')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, {
              'description': description.text.trim(),
              'amount': amount.text.trim(),
              'direction': direction, 'dueAt': dueAt,
            }), child: const Text('Registrar')),
          ],
        ),
      ),
    );
    description.dispose(); amount.dispose();
    if (result == null) return;
    final text = result['amount'] as String;
    final parts = text.split(RegExp(r'[,.]'));
    final valid = RegExp(r'^\d{1,8}([,.]\d{1,2})?$').hasMatch(text);
    final cents = valid ? int.parse(parts[0]) * 100 +
        (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0) : null;
    if (cents == null || cents == 0 || (result['description'] as String).isEmpty) {
      setState(() => error = 'Confira a descrição e o valor, por exemplo 150,00.');
      return;
    }
    try {
      await di<ApiClient>().call('finance-entries-create', {
        'workspaceId': workspaceId, 'description': result['description'],
        'amount': cents, 'direction': result['direction'],
        'dueAt': (result['dueAt'] as DateTime).toUtc().toIso8601String(),
        'idempotencyKey': const Uuid().v4(),
      });
      refresh();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  Future<void> settle(Map entry) async {
    try {
      await di<ApiClient>().call('finance-entries-settle', {
        'workspaceId': workspaceId, 'entryId': entry['id'],
      });
      refresh();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) => PageWidth(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 20),
      Text('Financeiro', style: Theme.of(context).textTheme.headlineMedium),
      const Text('Valores registrados pela empresa. Uma reserva não conta como pagamento.'),
      const SizedBox(height: 16),
      Wrap(spacing: 12, runSpacing: 12, children: [
        FilledButton.icon(onPressed: add, icon: const Icon(Icons.add),
          label: const Text('Novo lançamento')),
        OutlinedButton(onPressed: () async {
          final date = await showDatePicker(context: context,
            initialDate: DateTime.parse('$month-01'),
            firstDate: DateTime(2020), lastDate: DateTime(2100));
          if (date != null) {
            month = '${date.year}-${date.month.toString().padLeft(2, '0')}';
            refresh();
          }
        }, child: Text('Mês: $month')),
      ]),
      const SizedBox(height: 16),
      if (error != null) Notice(message: error!),
      RemoteData(future: summary, retry: refresh, builder: (data) =>
        Wrap(spacing: 12, runSpacing: 12, children: [
          for (final entry in [
            ('Previsto a receber', data['plannedIncome']),
            ('Recebido', data['received']),
            ('Previsto a pagar', data['plannedExpense']),
            ('Pago', data['paid']),
          ])
            Card(child: Padding(padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(entry.$1, style: const TextStyle(color: CormexTheme.muted)),
                Text(money(entry.$2), style: Theme.of(context).textTheme.titleLarge),
              ]))),
        ])),
      const SizedBox(height: 20),
      RemoteData(future: entries, retry: refresh, builder: (data) {
        final items = data['items'] as List? ?? [];
        if (items.isEmpty) return const Notice(message: 'Sem lançamentos neste mês.');
        return Column(children: [
          for (final entry in items)
            Card(child: ListTile(
              title: Text(entry['description'].toString()),
              subtitle: Text('${entry['direction'] == 'income' ? 'Receita' : 'Despesa'}'
                  ' • ${entry['status']} • ${entry['dueAt']}'),
              trailing: entry['status'] == 'planned'
                  ? OutlinedButton(onPressed: () => settle(entry),
                      child: Text(entry['direction'] == 'income'
                          ? 'Confirmar recebimento' : 'Marcar pago'))
                  : Text(money(entry['amount'])),
            )),
          if (data['nextCursor'] != null)
            const Notice(message: 'Há mais lançamentos neste período.'),
        ]);
      }),
    ]),
  );
}
