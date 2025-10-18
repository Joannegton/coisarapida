import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coisarapida/core/utils/snackbar_utils.dart';
import 'package:coisarapida/core/constants/app_routes.dart';
import 'package:coisarapida/features/autenticacao/presentation/providers/auth_provider.dart';
import '../providers/seguranca_provider.dart';
import 'dart:async';

/// Página para verificação de telefone por SMS
class VerificacaoTelefonePage extends ConsumerStatefulWidget {
  const VerificacaoTelefonePage({super.key});

  @override
  ConsumerState<VerificacaoTelefonePage> createState() => _VerificacaoTelefonePageState();
}

class _VerificacaoTelefonePageState extends ConsumerState<VerificacaoTelefonePage> {
  final _telefoneController = TextEditingController();
  final _codigoController = TextEditingController();
  
  bool _enviando = false;
  bool _verificando = false;
  bool _codigoEnviado = false;
  final ValueNotifier<int> _segundosRestantesNotifier = ValueNotifier(0);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _carregarTelefone();
  }

  @override
  void dispose() {
    _telefoneController.dispose();
    _codigoController.dispose();
    _segundosRestantesNotifier.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _carregarTelefone() {
    print('📱 [FRONTEND] Carregando telefone do usuário...');
    final usuarioAsync = ref.read(usuarioAtualStreamProvider);
    final usuario = usuarioAsync.value;
    print('📱 [FRONTEND] Estado do usuário: ${usuarioAsync}');
    print('📱 [FRONTEND] Dados do usuário: $usuario');

    if (usuario?.telefone != null) {
      print('📱 [FRONTEND] Telefone encontrado: ${usuario!.telefone}');
      _telefoneController.text = usuario.telefone!;
      print('📱 [FRONTEND] Telefone definido no controller: ${_telefoneController.text}');
    } else {
      print('📱 [FRONTEND] Nenhum telefone encontrado no usuário');
    }
  }

  void _iniciarContador() {
    print('⏰ [FRONTEND] Iniciando contador de 120 segundos');
    _segundosRestantesNotifier.value = 120; // 2 minutos
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_segundosRestantesNotifier.value > 0) {
        _segundosRestantesNotifier.value--;
        if (_segundosRestantesNotifier.value % 30 == 0) { // Log a cada 30 segundos
          print('⏰ [FRONTEND] Contador: ${_segundosRestantesNotifier.value} segundos restantes');
        }
      } else {
        print('⏰ [FRONTEND] Contador finalizado');
        timer.cancel();
      }
    });
  }

  String _formatarTelefone(String telefone) {
    print('🔧 [FRONTEND] Formatando telefone: $telefone');
    // Remove tudo que não é número
    telefone = telefone.replaceAll(RegExp(r'[^\d]'), '');
    print('🔧 [FRONTEND] Após remover não-dígitos: $telefone');

    return telefone;
  }

  Future<void> _enviarCodigo() async {
    final telefone = _telefoneController.text.trim();

    print('📱 [FRONTEND] Iniciando envio de código SMS');
    print('📱 [FRONTEND] Telefone digitado: $telefone');

    if (telefone.isEmpty) {
      print('❌ [FRONTEND] Telefone vazio');
      SnackBarUtils.mostrarErro(context, 'Digite seu telefone');
      return;
    }

    final telefoneFormatado = _formatarTelefone(telefone);
    print('📱 [FRONTEND] Telefone formatado: $telefoneFormatado');

    // Validar formato
    if (!RegExp(r'^\d{11}$').hasMatch(telefoneFormatado)) {
      print('❌ [FRONTEND] Telefone com formato inválido');
      SnackBarUtils.mostrarErro(
        context,
        'Telefone inválido. Use formato: (XX) XXXXX-XXXX',
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      final usuario = ref.read(usuarioAtualStreamProvider).value;
      if (usuario == null) {
        throw Exception('Usuário não encontrado');
      }

      await ref.read(verificacaoTelefoneProvider.notifier).enviarCodigoSMS(
        telefone: telefoneFormatado,
      );

      setState(() {
        _codigoEnviado = true;
        _codigoController.clear();
      });
      _iniciarContador();

      if (mounted) {
        SnackBarUtils.mostrarSucesso(
          context,
          'Código enviado para ${_formatarTelefoneDisplay(telefone)}',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.mostrarErro(context, 'Erro ao enviar código: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }

  Future<void> _verificarCodigo(String telefone) async {
    final codigo = _codigoController.text.trim();

    
    if (codigo.isEmpty || codigo.length != 6) {
      SnackBarUtils.mostrarErro(context, 'Digite o código de 6 dígitos');
      return;
    }

    setState(() => _verificando = true);

    try {
      final usuario = ref.read(usuarioAtualStreamProvider).value;
      if (usuario == null) {
        throw Exception('Usuário não encontrado');
      }

      await ref.read(verificacaoTelefoneProvider.notifier).verificarCodigoSMS(
        usuarioId: usuario.id,
        codigo: codigo,
        telefone: telefone
      );

      if (mounted) {
        SnackBarUtils.mostrarSucesso(
          context,
          'Telefone verificado com sucesso! ✅',
        );
        ref.invalidate(usuarioAtualStreamProvider);
        context.push(AppRoutes.verificacaoResidencia);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.mostrarErro(context, 'Erro ao verificar código: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _verificando = false);
      }
    }
  }

  Future<void> _reenviarCodigo() async {
    if (_segundosRestantesNotifier.value > 0) {
      SnackBarUtils.mostrarInfo(
        context,
        'Aguarde ${_segundosRestantesNotifier.value} segundos para reenviar',
      );
      return;
    }

    await _enviarCodigo();
  }  String _formatarTelefoneDisplay(String telefone) {
    telefone = telefone.replaceAll(RegExp(r'[^\d]'), '');
    if (telefone.length == 11) {
      return '(${telefone.substring(0, 2)}) ${telefone.substring(2, 7)}-${telefone.substring(7)}';
    }
    return telefone;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usuarioAsync = ref.watch(usuarioAtualStreamProvider);
    final usuario = usuarioAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificação de Telefone'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner informativo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Esta verificação é opcional, mas ajuda outros usuários a confiarem mais em você.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Informações
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.phone_android, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Verificação por SMS',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Enviaremos um código de 6 dígitos para seu telefone. '
                      'Digite o código para confirmar sua identidade.',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Campo de telefone
            if (!_codigoEnviado) ...[
              TextFormField(
                controller: _telefoneController,
                decoration: InputDecoration(
                  labelText: 'Telefone',
                  hintText: '(XX) XXXXX-XXXX',
                  prefixIcon: const Icon(Icons.phone),
                  border: const OutlineInputBorder(),
                  suffixIcon: usuario?.telefone != null && usuario!.telefone!.isNotEmpty
                      ? Icon(Icons.verified, color: theme.colorScheme.primary)
                      : null,
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _enviando ? null : _enviarCodigo,
                icon: _enviando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_enviando ? 'Enviando...' : 'Enviar Código'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ],

            // Campo de código
            if (_codigoEnviado) ...[
              Text(
                'Código enviado para ${_formatarTelefoneDisplay(_telefoneController.text)}',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _codigoController,
                decoration: const InputDecoration(
                  labelText: 'Código de verificação',
                  hintText: '000000',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                autofocus: true,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _verificando ? null : () => _verificarCodigo(_telefoneController.text),
                icon: _verificando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_verificando ? 'Verificando...' : 'Verificar Código'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<int>(
                valueListenable: _segundosRestantesNotifier,
                builder: (context, segundos, child) {
                  return TextButton.icon(
                    onPressed: segundos > 0 ? null : _reenviarCodigo,
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      segundos > 0
                          ? 'Reenviar em $segundos s'
                          : 'Reenviar Código',
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _codigoEnviado = false;
                    _codigoController.clear();
                    _segundosRestantesNotifier.value = 0;
                  });
                },
                child: const Text('Alterar telefone'),
              ),
            ],

            const SizedBox(height: 24),

            // Aviso
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'O código expira em 10 minutos. Você pode solicitar até 3 vezes.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
