import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/di/registry.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

const orderStates = {
  'opened': 'Aberta', 'inspection': 'Em vistoria',
  'awaiting_approval': 'Aguardando aprovação',
  'awaiting_parts': 'Aguardando peças', 'in_service': 'Em execução',
  'ready_for_pickup': 'Pronto para retirada',
  'delivered': 'Entregue', 'canceled': 'Cancelada',
};

class ServiceOrderPage extends StatefulWidget {
  const ServiceOrderPage({super.key, required this.id});
  final String id;
  @override
  State<ServiceOrderPage> createState() => _ServiceOrderPageState();
}

class _ServiceOrderPageState extends State<ServiceOrderPage> {
  late Future<Map<String, dynamic>> future = load();
  String? error;
  bool busy = false;
  Future<Map<String, dynamic>> load() =>
      di<ApiClient>().call('service-orders-get', {'orderId': widget.id});
  void refresh() => setState(() => future = load());

  Future<void> act(String endpoint, Map<String, dynamic> params) async {
    setState(() { error = null; busy = true; });
    try {
      await di<ApiClient>().call(endpoint, {'orderId': widget.id, ...params});
      refresh();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> inspect(List current) async {
    final area = TextEditingController();
    final finding = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar vistoria'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: area,
              decoration: const InputDecoration(labelText: 'Área verificada')),
          TextField(controller: finding, maxLines: 3,
              decoration: const InputDecoration(labelText: 'Achados e diagnóstico')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Voltar')),
          FilledButton(onPressed: () => Navigator.pop(context, {
            'area': area.text.trim(), 'finding': finding.text.trim(),
          }), child: const Text('Salvar')),
        ],
      ),
    );
    area.dispose(); finding.dispose();
    if (result != null) {
      await act('service-orders-inspection-upsert', {'items': [...current, result]});
    }
  }

  Future<void> estimate() async {
    final description = TextEditingController();
    final amount = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar orçamento'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: description,
              decoration: const InputDecoration(labelText: 'Serviço ou peça')),
          TextField(controller: amount, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Valor em reais',
                hintText: 'Ex.: 150,00')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Voltar')),
          FilledButton(onPressed: () => Navigator.pop(context, {
            'description': description.text.trim(),
            'amount': amount.text.trim(),
          }), child: const Text('Enviar')),
        ],
      ),
    );
    description.dispose(); amount.dispose();
    if (result == null) return;
    final amountText = result['amount']!;
    final parts = amountText.split(RegExp(r'[,.]'));
    final validAmount = RegExp(r'^\d{1,8}([,.]\d{1,2})?$').hasMatch(amountText);
    final cents = validAmount
        ? int.parse(parts[0]) * 100 +
            (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0)
        : null;
    if (cents == null || cents < 0 || result['description']!.isEmpty) {
      setState(() => error = 'Informe descrição e valor no formato 150,00.');
      return;
    }
    await act('service-orders-estimate-submit', {'items': [
      {'description': result['description'], 'amount': cents},
    ]});
  }

  @override
  Widget build(BuildContext context) => PublicFrame(
    child: SingleChildScrollView(
      child: PageWidth(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 22),
          Text('Ordem de serviço',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 14),
          RemoteData(future: future, retry: refresh, builder: (data) {
            final inspection = data['inspection'] as List? ?? [];
            final estimate = data['estimate'] as Map?;
            final status = data['status']?.toString() ?? '';
            final canManage = data['canManage'] == true;
            final canApprove = data['canApprove'] == true;
            return Card(child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Chip(label: Text(orderStates[status] ?? status)),
                const SizedBox(height: 12),
                Text('Veículo: ${data['vehicle']}',
                    style: Theme.of(context).textTheme.titleLarge),
                Text('Agendamento: ${data['bookingId']}'),
                const SizedBox(height: 20),
                Text('Vistoria', style: Theme.of(context).textTheme.titleMedium),
                for (final item in inspection)
                  ListTile(title: Text(item['area'].toString()),
                    subtitle: Text(item['finding'].toString())),
                if (inspection.isEmpty) const Text('Ainda não há vistoria registrada.'),
                const SizedBox(height: 18),
                Text('Orçamento', style: Theme.of(context).textTheme.titleMedium),
                if (estimate == null) const Text('Ainda não há orçamento.'),
                if (estimate != null) ...[
                  for (final item in estimate['items'] as List)
                    ListTile(title: Text(item['description'].toString()),
                      trailing: Text('R\$ ${((item['amount'] as num) / 100).toStringAsFixed(2)}')),
                  Text('Total: R\$ ${((estimate['total'] as num) / 100).toStringAsFixed(2)}'),
                  Text('Situação: ${estimate['decision']}'),
                ],
                const SizedBox(height: 16),
                if (error != null) Notice(message: error!),
                if (busy) const LinearProgressIndicator(color: CormexTheme.forest),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  if (canManage && ['opened', 'inspection'].contains(status))
                    OutlinedButton(onPressed: busy ? null : () => inspect(inspection),
                      child: const Text('Registrar vistoria')),
                  if (canManage && ['inspection', 'awaiting_approval'].contains(status))
                    FilledButton(onPressed: busy ? null : estimate,
                      child: const Text('Enviar orçamento')),
                  if (canApprove && status == 'awaiting_approval' &&
                      estimate?['decision'] == 'pending')
                    for (final decision in ['approved', 'rejected'])
                      OutlinedButton(
                        onPressed: busy ? null : () => act(
                          'service-orders-estimate-decision',
                          {'estimateVersion': estimate!['version'], 'decision': decision}),
                        child: Text(decision == 'approved'
                            ? 'Aprovar orçamento' : 'Recusar orçamento'),
                      ),
                  if (canManage && status == 'in_service')
                    OutlinedButton(onPressed: busy ? null : () => act(
                      'service-orders-status-update', {'status': 'ready_for_pickup'}),
                      child: const Text('Pronto para retirada')),
                  if (canManage && status == 'ready_for_pickup')
                    OutlinedButton(onPressed: busy ? null : () => act(
                      'service-orders-status-update', {'status': 'delivered'}),
                      child: const Text('Marcar como entregue')),
                  OutlinedButton(onPressed: () => context.go('/my-bookings'),
                    child: const Text('Meus agendamentos')),
                ]),
              ]),
            ));
          }),
        ]),
      ),
    ),
  );
}
