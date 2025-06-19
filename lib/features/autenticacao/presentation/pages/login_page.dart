import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:validatorless/validatorless.dart';
import '../providers/auth_provider.dart';
import '../widgets/campo_texto_customizado.dart';
import '../widgets/botao_google.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/utils/snackbar_utils.dart';

// Providers para controle de estado reativo usando Riverpod
final senhaVisivelProvider = StateProvider<bool>((ref) => false);
final loginEmProgressoProvider = StateProvider<_TipoLogin?>((ref) => null);
// final senhaVisivelProvider = StateProvider<bool>((ref) => false);
// final cadastroEmProgressoProvider = StateProvider<_TipoCadastro?>((ref) => null);

enum _TipoLogin {
  email,
  google,
}

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: LoginFormWidget(),
        ),
      ),
    );
  }
}

class LoginFormWidget extends ConsumerStatefulWidget {
  const LoginFormWidget({super.key});

  @override
  ConsumerState<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends ConsumerState<LoginFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  bool get _isEmailLoginFormValido =>
      _emailController.text.trim().isNotEmpty &&
      _senhaController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onInputChanged);
    _senhaController.addListener(_onInputChanged);
  }

  void _onInputChanged() => setState(() {});

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _fazerLogin() async {
    if (!_formKey.currentState!.validate()) return;
    ref.read(loginEmProgressoProvider.notifier).state = _TipoLogin.email;
    await ref.read(authControllerProvider.notifier).loginComEmail(
      email: _emailController.text.trim(),
      senha: _senhaController.text,
    );
  }

  Future<void> _loginComGoogle() async {
    ref.read(loginEmProgressoProvider.notifier).state = _TipoLogin.google;
    await ref.read(authControllerProvider.notifier).loginComGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final senhaVisivel = ref.watch(senhaVisivelProvider);
    final loginEmProgresso = ref.watch(loginEmProgressoProvider);
    final estaDigitandoEmail = _emailController.text.trim().isNotEmpty;

    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
          ref.invalidate(loginEmProgressoProvider);
        },
        error: (error, _) {
          SnackBarUtils.mostrarErro(context, error.toString());
          ref.invalidate(loginEmProgressoProvider);
        },
      );
    });

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),

          // Animação do título baseada no estado do campo de email
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: estaDigitandoEmail
                ? _buildTitulo(theme, key: const ValueKey('titulo_digitando'))
                : _buildTitulo(theme, key: const ValueKey('titulo_padrao')),
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
            obscureText: !senhaVisivel,
            suffixIcon: IconButton(
              icon: Icon(
                senhaVisivel ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () => ref.read(senhaVisivelProvider.notifier).state = !senhaVisivel,
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

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: ElevatedButton(
              key: ValueKey(_isEmailLoginFormValido && !authState.isLoading),
              onPressed: (authState.isLoading || !_isEmailLoginFormValido)
                  ? null
                  : _fazerLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                disabledBackgroundColor: theme.colorScheme.primary.withAlpha(153),
                foregroundColor: theme.colorScheme.onPrimary,
                disabledForegroundColor: theme.colorScheme.onPrimary.withAlpha(153),
              ),
              child: authState.isLoading && loginEmProgresso == _TipoLogin.email
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white70,
                      ),
                    )
                  : const Text('Entrar'),
            ),
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
                    color: theme.colorScheme.onSurface.withAlpha(153),
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),

          const SizedBox(height: 24),

          BotaoGoogle(
            onPressed: authState.isLoading ? null : _loginComGoogle,
            isLoading: authState.isLoading && loginEmProgresso == _TipoLogin.google,
          ),

          const SizedBox(height: 32),

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
    );
  }

  // key para identificar transições
  Widget _buildTitulo(ThemeData theme, {required Key key}) {
    return Column(
      key: key,
      children: [
        Image.asset(
          "assets/images/coisa_rapida_logo.png",
          width: 100,
          height: 100,
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
            color: theme.colorScheme.onSurface.withAlpha(153),
          ),
        ),
      ],
    );
  }
}
