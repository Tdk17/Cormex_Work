import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/config/app_config.dart';
import '../../core/di/registry.dart';
import '../../core/auth/session_store.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.mode, this.from});
  final String mode;
  final String? from;
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  bool accepted = false;
  bool showPassword = false;
  String? error;
  String? success;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    if (widget.mode == 'register' && !accepted) {
      setState(
        () => error = 'Leia e aceite os Termos e o Aviso de Privacidade.',
      );
      return;
    }
    setState(() {
      busy = true;
      error = null;
      success = null;
    });
    try {
      if (widget.mode == 'reset') {
        final data = await di<ApiClient>().call('auth-password-reset-request', {
          'email': email.text.trim(),
        });
        if (mounted) setState(() => success = data['message']?.toString());
      } else {
        if (widget.mode == 'register') {
          await di<ApiClient>().call('auth-register', {
            'name': name.text.trim(),
            'email': email.text.trim(),
            'password': password.text,
            'acceptTerms': true,
            'termsVersion': AppConfig.termsVersion,
            'privacyVersion': AppConfig.privacyVersion,
          });
        }
        await di<SessionStore>().login(email.text.trim(), password.text);
        if (!mounted) return;
        final from = widget.from;
        context.go(
          from != null && from.startsWith('/') && !from.startsWith('//')
              ? from
              : '/client',
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final registering = widget.mode == 'register';
    final resetting = widget.mode == 'reset';
    final card = Card(
              child: Padding(
                padding: EdgeInsets.all(
                  MediaQuery.sizeOf(context).width < 600 ? 25 : 38,
                ),
                child: Form(
                  key: form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: CormexTheme.pale,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            color: CormexTheme.forest,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'ACESSO À PLATAFORMA',
                        style: TextStyle(
                          color: CormexTheme.forest,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        resetting
                            ? 'Recuperar senha'
                            : registering
                                ? 'Criar conta'
                                : 'Entre na sua conta',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        resetting
                            ? 'Enviaremos instruções se este e-mail estiver cadastrado.'
                            : 'Sua operação começa com dados reais e uma agenda organizada.',
                      ),
                      const SizedBox(height: 30),
                      if (registering) ...[
                        TextFormField(
                          controller: name,
                          decoration: const InputDecoration(
                            labelText: 'Nome',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: (v) => (v?.trim().isEmpty ?? true)
                              ? 'Informe seu nome.'
                              : null,
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'Informe um e-mail válido.'
                            : null,
                      ),
                      if (!resetting) ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: password,
                          obscureText: !showPassword,
                          autofillHints: [
                            registering
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            prefixIcon:
                                const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              tooltip: showPassword
                                  ? 'Ocultar senha'
                                  : 'Mostrar senha',
                              onPressed: () => setState(
                                () => showPassword = !showPassword,
                              ),
                              icon: Icon(
                                showPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          validator: (v) => registering && (v?.length ?? 0) < 12
                              ? 'Use pelo menos 12 caracteres.'
                              : (v?.isEmpty ?? true)
                                  ? 'Informe sua senha.'
                                  : null,
                        ),
                      ],
                      if (registering) ...[
                        const SizedBox(height: 12),
                        if (!AppConfig.canRegister)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: CormexTheme.pale,
                              border: Border.all(color: CormexTheme.sage),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    color: CormexTheme.forest, size: 20),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'O cadastro será liberado após a publicação dos Termos e do Aviso de Privacidade.',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (AppConfig.canRegister) ...[
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () =>
                                    launchUrl(Uri.parse(AppConfig.termsUrl)),
                                child: const Text('Ler Termos de Uso'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    launchUrl(Uri.parse(AppConfig.privacyUrl)),
                                child: const Text('Ler Aviso de Privacidade'),
                              ),
                            ],
                          ),
                          CheckboxListTile(
                            value: accepted,
                            onChanged: (v) =>
                                setState(() => accepted = v ?? false),
                            title: const Text(
                              'Li e aceito os Termos e o Aviso de Privacidade',
                            ),
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ],
                      ],
                      if (error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      if (success != null) ...[
                        const SizedBox(height: 12),
                        Text(success!),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        style: ButtonStyle(
                          side: WidgetStateProperty.resolveWith((states) =>
                              BorderSide(
                                color: states.contains(WidgetState.disabled)
                                    ? CormexTheme.muted
                                    : CormexTheme.forest,
                                width: 1.6,
                              )),
                        ),
                        onPressed: busy ||
                                (registering && !AppConfig.canRegister)
                            ? null
                            : submit,
                        child: Text(
                          busy
                              ? 'Aguarde...'
                              : resetting
                                  ? 'Enviar instruções'
                                  : registering
                                      ? 'Criar conta'
                                      : 'Entrar',
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (!registering && !resetting)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.go('/reset'),
                            child: const Text('Esqueci minha senha'),
                          ),
                        ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Text(
                            registering
                                ? 'Já faz parte do Cormex Work?'
                                : 'Ainda não tem conta?',
                            style: const TextStyle(color: CormexTheme.muted),
                          ),
                          OutlinedButton(
                            onPressed: () => context.go((registering
                                    ? '/login'
                                    : '/register') +
                                (widget.from == null
                                    ? ''
                                    : '?from=${Uri.encodeComponent(widget.from!)}')),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: CormexTheme.forest,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              registering ? 'Entrar' : 'Criar conta',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
    return PublicFrame(
      child: SingleChildScrollView(
        child: PageWidth(
          maxWidth: 1180,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 42),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 890;
                if (compact) {
                  return Column(
                    children: [
                      const _AuthIntro(compact: true),
                      const SizedBox(height: 20),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: card,
                      ),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(child: _AuthIntro()),
                    const SizedBox(width: 30),
                    SizedBox(width: 500, child: card),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthIntro extends StatelessWidget {
  const _AuthIntro({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(compact ? 28 : 42),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [CormexTheme.deep, CormexTheme.petroleum],
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF2A6259),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                color: CormexTheme.sage,
              ),
            ),
            SizedBox(height: compact ? 34 : 95),
            const Text(
              'BEM-VINDO AO CORMEX WORK',
              style: TextStyle(
                color: CormexTheme.sage,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            Text.rich(
              const TextSpan(
                children: [
                  TextSpan(text: 'Sua operação,\n'),
                  TextSpan(
                    text: 'mais simples.',
                    style: TextStyle(color: CormexTheme.sage),
                  ),
                ],
              ),
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 36 : 43,
                fontWeight: FontWeight.w800,
                height: 1.1,
                letterSpacing: -1.3,
              ),
            ),
            const SizedBox(height: 19),
            const Text(
              'Entre para organizar serviços, horários e reservas '
              'em um só espaço.',
              style: TextStyle(
                color: Color(0xFFC6D8D3),
                fontSize: 16,
                height: 1.55,
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 48),
              const Divider(color: Color(0xFF456762)),
              const SizedBox(height: 20),
              const _AuthBenefit(
                icon: Icons.calendar_month_outlined,
                text: 'Agenda organizada para sua rotina',
              ),
              const SizedBox(height: 17),
              const _AuthBenefit(
                icon: Icons.storefront_outlined,
                text: 'Serviços apresentados com clareza',
              ),
              const SizedBox(height: 17),
              const _AuthBenefit(
                icon: Icons.groups_outlined,
                text: 'Equipe no mesmo fluxo de trabalho',
              ),
            ],
          ],
        ),
      );
}

class _AuthBenefit extends StatelessWidget {
  const _AuthBenefit({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 21, color: CormexTheme.sage),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFFE1ECE8)),
            ),
          ),
        ],
      );
}
