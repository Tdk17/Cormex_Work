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
        final hasWorkspace = di<SessionStore>().workspaceId.value != null;
        context.go(
          from != null && from.startsWith('/') && !from.startsWith('//')
              ? from
              : hasWorkspace
                  ? '/app/dashboard'
                  : '/my-bookings',
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
    return PublicFrame(
      child: Center(
        child: SingleChildScrollView(
          child: PageWidth(
            maxWidth: 560,
            child: Card(
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
                          decoration: const InputDecoration(labelText: 'Nome'),
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
                        decoration: const InputDecoration(labelText: 'E-mail'),
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'Informe um e-mail válido.'
                            : null,
                      ),
                      if (!resetting) ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: password,
                          obscureText: true,
                          autofillHints: [
                            registering
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          decoration: const InputDecoration(labelText: 'Senha'),
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
                          const Text(
                            'Cadastro indisponível até a publicação dos Termos e da Privacidade.',
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
                        TextButton(
                          onPressed: () => context.go('/reset'),
                          child: const Text('Esqueci minha senha'),
                        ),
                      TextButton(
                        onPressed: () => context.go((registering
                                ? '/login'
                                : '/register') +
                            (widget.from == null
                                ? ''
                                : '?from=${Uri.encodeComponent(widget.from!)}')),
                        child: Text(
                          registering ? 'Já tenho conta' : 'Criar uma conta',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
