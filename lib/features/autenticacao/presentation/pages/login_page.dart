import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:validatorless/validatorless.dart';

import '../providers/auth_provider.dart';
import '../widgets/campo_texto_customizado.dart';
import '../widgets/botao_google.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/utils/snackbar_utils.dart';

enum _TipoLogin {
  email,
  google,
}

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
  bool _camposPreenchidos = false;
  _TipoLogin? _loginEmProgresso;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_atualizarEstadoBotao);
    _senhaController.addListener(_atualizarEstadoBotao);
  }

  void _atualizarEstadoBotao() {
    setState(() {
      _camposPreenchidos = _emailController.text.isNotEmpty && _senhaController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _fazerLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loginEmProgresso = _TipoLogin.email;
    });

    await ref.read(authControllerProvider.notifier).loginComEmail(
      email: _emailController.text.trim(),
      senha: _senhaController.text,
    );
  }

  Future<void> _loginComGoogle() async {
    setState(() {
      _loginEmProgresso = _TipoLogin.google;
    });

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
          if (mounted) {
            setState(() => _loginEmProgresso = null);
          }
          // Login bem-sucedido, AuthGuard cuidará do redirecionamento.
          // No entanto, para uma transição mais explícita da LoginPage:
          if (mounted) {
            context.go(AppRoutes.home);
          }
        },
        error: (error, _) {
          if (mounted) {
            SnackBarUtils.mostrarErro(context, error.toString());
            setState(() => _loginEmProgresso = null);
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
                          Icons.bolt,
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
                          color: theme.colorScheme.onSurface.withAlpha((255 * 0.6).round()),
                        ),
                      ),
                    ],
                  ),
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
                  textInputAction: TextInputAction.next,
                ),
                
                const SizedBox(height: 16),
                
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
                
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.esqueciSenha),
                    child: const Text('Esqueci minha senha'),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                ElevatedButton(
                  onPressed: (authState.isLoading || !_camposPreenchidos) ? null : _fazerLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    disabledBackgroundColor: theme.colorScheme.primary.withAlpha((255 * 0.6).round()),
                    foregroundColor: theme.colorScheme.onPrimary,
                    disabledForegroundColor: theme.colorScheme.onPrimary.withAlpha((255 * 0.6).round()),
                  ),
                  child: authState.isLoading && _loginEmProgresso == _TipoLogin.email
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary.withAlpha((255 * 0.38).round()),
                          ),
                        )
                      : const Text('Entrar'),
                ),
                
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ou',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha((255 * 0.6).round()),
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                BotaoGoogle(
                  onPressed: authState.isLoading ? null : _loginComGoogle,
                  isLoading: authState.isLoading && _loginEmProgresso == _TipoLogin.google,
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
