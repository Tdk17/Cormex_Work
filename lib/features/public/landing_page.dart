import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/config/app_config.dart';
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
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      CormexTheme.deep,
                      CormexTheme.petroleum,
                      Color(0xFF1B4C4C),
                    ],
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      right: -130,
                      top: -190,
                      child: Container(
                        width: 540,
                        height: 540,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0x224CB7A0)),
                          gradient: const RadialGradient(
                            colors: [Color(0x284A977D), Color(0x00123D43)],
                          ),
                        ),
                      ),
                    ),
                    PageWidth(
                      maxWidth: 1200,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 74),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final compact = constraints.maxWidth < 900;
                            if (compact) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  _HeroCopy(compact: true),
                                  SizedBox(height: 42),
                                  _HeroPanel(),
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: const [
                                Expanded(child: _HeroCopy()),
                                SizedBox(width: 64),
                                SizedBox(width: 392, child: _HeroPanel()),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PageWidth(
                maxWidth: 1200,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 65),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!AppConfig.isConfigured) ...[
                        const Notice(
                          message: 'Estamos preparando os agendamentos e o '
                              'cadastro de empresas. Volte em breve.',
                        ),
                        const SizedBox(height: 36),
                      ],
                      const _Eyebrow('UMA OPERAÇÃO MAIS CLARA'),
                      const SizedBox(height: 14),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 660),
                        child: Text(
                          'O essencial para atender bem, sem perder o controle.',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Um espaço para organizar serviços, horários e reservas '
                        'com a rotina da sua empresa em primeiro lugar.',
                        style: TextStyle(
                          fontSize: 16,
                          color: CormexTheme.muted,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 32),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final columns = width >= 900
                              ? 3
                              : width >= 590
                                  ? 2
                                  : 1;
                          final cardWidth = (width - (columns - 1) * 16) /
                              columns;
                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _Feature(
                                width: cardWidth,
                                icon: Icons.event_available_outlined,
                                title: 'Agenda sob controle',
                                body: 'Horários reais e disponibilidade '
                                    'calculada a partir da sua operação.',
                              ),
                              _Feature(
                                width: cardWidth,
                                icon: Icons.storefront_outlined,
                                title: 'Sua vitrine de serviços',
                                body: 'Apresente o que sua empresa faz em '
                                    'um perfil público organizado.',
                              ),
                              _Feature(
                                width: cardWidth,
                                icon: Icons.groups_2_outlined,
                                title: 'Equipe e permissões',
                                body: 'Cada pessoa acessa o que precisa '
                                    'para realizar seu trabalho.',
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                color: Colors.white,
                child: PageWidth(
                  maxWidth: 1200,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 54),
                    child: LayoutBuilder(
                      builder: (context, constraints) => Wrap(
                        spacing: 36,
                        runSpacing: 28,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: constraints.maxWidth < 800
                                ? constraints.maxWidth
                                : 650,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _Eyebrow('FEITO PARA O SEU DIA A DIA'),
                                const SizedBox(height: 12),
                                Text(
                                  'Mais organização para o trabalho acontecer.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Comece com sua empresa, configure os '
                                  'serviços e deixe a agenda pronta para '
                                  'receber reservas.',
                                  style: TextStyle(
                                    color: CormexTheme.muted,
                                    height: 1.55,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => context.go('/onboarding'),
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: const Text('Cadastrar minha empresa'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                color: CormexTheme.deep,
                child: PageWidth(
                  maxWidth: 1200,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Wrap(
                      spacing: 24,
                      runSpacing: 12,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: const [
                        Brand(light: true),
                        Text(
                          'Agenda, equipe e serviços em um só lugar.',
                          style: TextStyle(color: Color(0xFFB7CAC7)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              border: Border.all(color: const Color(0x3756A18F)),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Text(
              'CORMEX WORK  /  GESTÃO DE SERVIÇOS',
              style: TextStyle(
                color: CormexTheme.sage,
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 28),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 660),
            child: Text.rich(
              TextSpan(
                children: const [
                  TextSpan(text: 'Organize a rotina.\n'),
                  TextSpan(
                    text: 'Valorize cada atendimento.',
                    style: TextStyle(color: CormexTheme.sage),
                  ),
                ],
              ),
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 42 : 56,
                fontWeight: FontWeight.w800,
                height: 1.08,
                letterSpacing: -2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: const Text(
              'Serviços, horários e reservas conectados em uma experiência '
              'simples para sua empresa e seus clientes.',
              style: TextStyle(
                color: Color(0xFFC5D6D2),
                fontSize: 17,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: () => context.go('/onboarding'),
                style: FilledButton.styleFrom(
                  backgroundColor: CormexTheme.sage,
                  foregroundColor: CormexTheme.deep,
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 19),
                label: const Text('Começar como empresa'),
              ),
              OutlinedButton(
                onPressed: () => context.go('/find'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF749B92)),
                ),
                child: const Text('Encontrar um serviço'),
              ),
            ],
          ),
        ],
      );
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF153A3D),
          border: Border.all(color: const Color(0xFF416B66)),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x36041318),
              blurRadius: 40,
              offset: Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A6259),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    size: 19,
                    color: CormexTheme.sage,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Sua operação em um lugar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Divider(color: Color(0xFF3E6762), height: 1),
            const SizedBox(height: 12),
            const _PanelRow(
              icon: Icons.calendar_today_outlined,
              title: 'Agenda',
              subtitle: 'Horários disponíveis',
            ),
            const _PanelRow(
              icon: Icons.design_services_outlined,
              title: 'Serviços',
              subtitle: 'Tudo o que você oferece',
            ),
            const _PanelRow(
              icon: Icons.people_outline_rounded,
              title: 'Equipe',
              subtitle: 'Acessos organizados',
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF244C49),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: CormexTheme.sage,
                    size: 19,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Mais clareza para atender melhor.',
                      style: TextStyle(color: Color(0xFFE2EFEB)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _PanelRow extends StatelessWidget {
  const _PanelRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title, subtitle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF28544F),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 20, color: CormexTheme.sage),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFFB6CBC6)),
                ),
              ],
            ),
          ],
        ),
      );
}

class _Feature extends StatelessWidget {
  const _Feature({
    required this.width,
    required this.icon,
    required this.title,
    required this.body,
  });
  final double width;
  final IconData icon;
  final String title, body;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: CormexTheme.pale,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: CormexTheme.forest, size: 24),
                ),
                const SizedBox(height: 27),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 9),
                Text(
                  body,
                  style: const TextStyle(
                    color: CormexTheme.muted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          color: CormexTheme.forest,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.7,
        ),
      );
}
