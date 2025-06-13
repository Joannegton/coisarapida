import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:validatorless/validatorless.dart';

import '../providers/auth_provider.dart';
import '../widgets/campo_texto_customizado.dart';
import '../widgets/botao_google.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/utils/snackbar_utils.dart';

/// Tela de login do usuário
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  
  bool _senhaVisivel = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _fazerLogin() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authControllerProvider.notifier).loginComEmail(
      email: _emailController.text.trim(),
      senha: _senhaController.text,
    );
  }

  Future<void> _loginComGoogle() async {
    await ref.read(authControllerProvider.notifier).loginComGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);

    // Escutar mudanças no estado de autenticação
    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
          // Login bem-sucedido, AuthGuard cuidará do redirecionamento.
          // No entanto, para uma transição mais explícita da LoginPage:
          if (mounted) {
            context.go(AppRoutes.home);
          }
        },
        error: (error, _) {
          if (mounted) {
            SnackBarUtils.mostrarErro(context, error.toString());
          }
        },
      );
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Logo e título
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.delivery_dining,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Bem-vindo de volta!',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Entre na sua conta para continuar',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Campo de email
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
                
                const SizedBox(height: 16),
                
                // Campo de senha
                CampoTextoCustomizado(
                  controller: _senhaController,
                  label: 'Senha',
                  hint: 'Digite sua senha',
                  prefixIcon: Icons.lock_outlined,
                  obscureText: !_senhaVisivel,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _senhaVisivel ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _senhaVisivel = !_senhaVisivel;
                      });
                    },
                  ),
                  validator: Validatorless.required('Senha é obrigatória'),
                ),
                
                const SizedBox(height: 8),
                
                // Link esqueci senha
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.esqueciSenha),
                    child: const Text('Esqueci minha senha'),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Botão de login
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _fazerLogin,
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Entrar'),
                ),
                
                const SizedBox(height: 24),
                
                // Divisor
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ou',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Botão Google
                BotaoGoogle(
                  onPressed: authState.isLoading ? null : _loginComGoogle,
                  isLoading: authState.isLoading,
                ),
                
                const SizedBox(height: 32),
                
                // Link para cadastro
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Não tem uma conta? ',
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.cadastro),
                      child: const Text('Cadastre-se'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
