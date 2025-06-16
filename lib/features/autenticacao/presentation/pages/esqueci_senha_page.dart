import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:validatorless/validatorless.dart';

import '../providers/auth_provider.dart';
import '../widgets/campo_texto_customizado.dart';
import '../../../../core/utils/snackbar_utils.dart';

class EsqueciSenhaPage extends ConsumerStatefulWidget {
  const EsqueciSenhaPage({super.key});

  @override
  ConsumerState<EsqueciSenhaPage> createState() => _EsqueciSenhaPageState();
}

class _EsqueciSenhaPageState extends ConsumerState<EsqueciSenhaPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _enviarEmailRecuperacao() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authControllerProvider.notifier)
        .enviarEmailRedefinicaoSenha(_emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);

    // Escutar mudanças no estado de autenticação
    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
          SnackBarUtils.mostrarSucesso(
            context,
            'Email de recuperação enviado! Verifique sua caixa de entrada.',
          );
          context.pop();
        },
        error: (error, _) {
          SnackBarUtils.mostrarErro(context, error.toString());
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar Senha'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha((255 * 0.1).round()),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.lock_reset,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Text(
                  'Esqueceu sua senha?',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Digite seu email abaixo e enviaremos um link para redefinir sua senha.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha((255 * 0.6).round()),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 48),
                
                CampoTextoCustomizado(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Digite seu email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validatorless.multiple([
                    Validatorless.required('Email é obrigatório'),
                    Validatorless.email('Digite um email válido'),
                  ]),
                ),
                
                const SizedBox(height: 32),
                
                ElevatedButton(
                  // A verificação do texto do controller pode ser feita diretamente aqui.
                  // O listener no controller e o setState() em _onEmailChanged não são mais necessários
                  // se o único propósito era habilitar/desabilitar este botão.
                  onPressed: authState.isLoading || _emailController.text.trim().isEmpty 
                      ? null
                      : _enviarEmailRecuperacao,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    disabledBackgroundColor: theme.colorScheme.primary.withAlpha((255 * 0.6).round()),
                    foregroundColor: theme.colorScheme.onPrimary,
                    disabledForegroundColor: theme.colorScheme.onPrimary.withAlpha((255 * 0.6).round()),
                  ),
                  child: authState.isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary.withAlpha((255 * 0.38).round()),
                          )
                        )
                      : const Text('Enviar Email de Recuperação'),
                ),
                
                const SizedBox(height: 24),
                
                // Voltar para login
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Voltar para o login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
