import 'package:coisarapida/core/constants/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:validatorless/validatorless.dart';

import '../providers/auth_provider.dart';
import '../widgets/campo_texto_customizado.dart';
import '../widgets/botao_google.dart';
import '../../../../core/utils/snackbar_utils.dart';

enum _TipoCadastro {
  email,
  google,
}



class CadastroPage extends ConsumerStatefulWidget {
  const CadastroPage({super.key});

  @override
  ConsumerState<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends ConsumerState<CadastroPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  
  bool _senhaVisivel = false;
  bool _confirmarSenhaVisivel = false;
  bool _aceitouTermos = false;
  _TipoCadastro? _cadastroEmProgresso;


  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _fazerCadastro() async {
    if (!_formKey.currentState!.validate()) return;
    
    // A verificação de _aceitouTermos é feita pela lógica de habilitação do botão
    setState(() {
      _cadastroEmProgresso = _TipoCadastro.email;
    });

    await ref.read(authControllerProvider.notifier).cadastrarComEmail(
      nome: _nomeController.text.trim(),
      email: _emailController.text.trim(),
      senha: _senhaController.text,
    );
  }

  Future<void> _loginComGoogle() async {
    setState(() {
      _cadastroEmProgresso = _TipoCadastro.google;
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
            setState(() => _cadastroEmProgresso = null);
          }

          SnackBarUtils.mostrarSucesso(
            context,
            'Conta criada com sucesso! Verifique seu email.',
          );
        },
        error: (error, _) {
          SnackBarUtils.mostrarErro(context, error.toString());
          if (mounted) {
            setState(() => _cadastroEmProgresso = null);
          }
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Conta'),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark ? Brightness.light : Brightness.dark,
          statusBarBrightness: Theme.of(context).brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Título e subtítulo
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Crie sua conta',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Preencha os dados abaixo para começar',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha((255 * 0.6).round()),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Campo de nome
                CampoTextoCustomizado(
                  controller: _nomeController,
                  label: 'Nome completo',
                  hint: 'Digite seu nome completo',
                  prefixIcon: Icons.person_outlined,
                  textCapitalization: TextCapitalization.words,
                  validator: Validatorless.multiple([
                    Validatorless.required('Nome é obrigatório'),
                    Validatorless.min(2, 'Nome deve ter pelo menos 2 caracteres'),
                  ]),
                  textInputAction: TextInputAction.next,
                ),
                
                const SizedBox(height: 16),
                
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
                  textInputAction: TextInputAction.next,
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
                  validator: Validatorless.multiple([
                    Validatorless.required('Senha é obrigatória'),
                    Validatorless.min(6, 'Senha deve ter pelo menos 6 caracteres'),
                  ]),
                  textInputAction: TextInputAction.next,
                ),
                
                const SizedBox(height: 16),
                
                // Campo de confirmar senha
                CampoTextoCustomizado(
                  controller: _confirmarSenhaController,
                  label: 'Confirmar senha',
                  hint: 'Digite sua senha novamente',
                  prefixIcon: Icons.lock_outlined,
                  obscureText: !_confirmarSenhaVisivel,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _confirmarSenhaVisivel 
                          ? Icons.visibility_off 
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _confirmarSenhaVisivel = !_confirmarSenhaVisivel;
                      });
                    },
                  ),
                  validator: Validatorless.multiple([
                    Validatorless.required('Confirmação de senha é obrigatória'),
                    Validatorless.compare(
                      _senhaController, 
                      'Senhas não coincidem',
                    ),
                  ]),
                  textInputAction: TextInputAction.done,
                ),
                
                const SizedBox(height: 24),
                
                // Checkbox termos de uso
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _aceitouTermos,
                      onChanged: (value) {
                        setState(() {
                          _aceitouTermos = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _aceitouTermos = !_aceitouTermos;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: RichText(
                            text: TextSpan(
                              style: theme.textTheme.bodyMedium,
                              children: [
                                const TextSpan(text: 'Eu aceito os '),
                                TextSpan(
                                  text: 'Termos de Uso',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const TextSpan(text: ' e a '),
                                TextSpan(
                                  text: 'Política de Privacidade',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _nomeController, // Pode ser qualquer um, ou agrupar com ValueNotifier<bool>
                  builder: (context, _, __) { // Usamos ValueListenableBuilder para reconstruir ao digitar
                    final bool camposValidos = _nomeController.text.trim().isNotEmpty &&
                                              _emailController.text.trim().isNotEmpty &&
                                              _senhaController.text.isNotEmpty &&
                                              _confirmarSenhaController.text.isNotEmpty &&
                                              _aceitouTermos;
                    return ElevatedButton(
                      onPressed: (authState.isLoading || !camposValidos) ? null : _fazerCadastro,
                      style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    disabledBackgroundColor: theme.colorScheme.primary.withAlpha((255 * 0.6).round()),
                    foregroundColor: theme.colorScheme.onPrimary,
                    disabledForegroundColor: theme.colorScheme.onPrimary.withAlpha((255 * 0.6).round()),
                  ),
                  child: authState.isLoading && _cadastroEmProgresso == _TipoCadastro.email
                      ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary.withAlpha((255 * 0.38).round()),
                        ),
                      )
                      : const Text('Criar Conta'),
                    );
                  }
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
                  isLoading: authState.isLoading && _cadastroEmProgresso == _TipoCadastro.google,
                ),
                
                const SizedBox(height: 15),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Já tem uma conta? ',
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Fazer login'),
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
