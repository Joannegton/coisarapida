import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:coisarapida/core/utils/snackbar_utils.dart';
import 'package:coisarapida/core/errors/exceptions.dart';
import 'package:coisarapida/features/autenticacao/presentation/providers/auth_provider.dart';
import 'package:coisarapida/features/autenticacao/domain/entities/endereco.dart';
import 'package:coisarapida/features/autenticacao/domain/entities/usuario.dart';
import 'package:coisarapida/features/autenticacao/domain/entities/status_endereco.dart';
import '../providers/seguranca_provider.dart';
import '../../domain/entities/verificacao_residencia.dart';

/// Página para verificação de residência
class VerificacaoResidenciaPage extends ConsumerStatefulWidget {
  const VerificacaoResidenciaPage({super.key});

  @override
  ConsumerState<VerificacaoResidenciaPage> createState() => _VerificacaoResidenciaPageState();
}

class _VerificacaoResidenciaPageState extends ConsumerState<VerificacaoResidenciaPage> {
  File? _comprovanteImagem;
  bool _enviando = false;

  // Controllers para endereço
  final _cepController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _salvandoEndereco = false;

  bool _camposPreenchidos = false; // Flag para evitar rebuilds desnecessários

  @override
  void initState() {
    super.initState();
    // Removido: _preencherCamposEndereco() - será chamado em didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Preencher campos apenas uma vez quando o widget for montado
    if (!_camposPreenchidos) {
      _preencherCamposEndereco();
      _camposPreenchidos = true;
    }
  }

  @override
  void dispose() {
    _cepController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  void _preencherCamposEndereco() {
    final usuarioAsync = ref.read(usuarioAtualStreamProvider);
    final usuario = usuarioAsync.value;
    if (usuario?.endereco != null) {
      final endereco = usuario!.endereco!;
      _cepController.text = endereco.cep;
      _ruaController.text = endereco.rua;
      _numeroController.text = endereco.numero;
      _complementoController.text = endereco.complemento ?? '';
      _bairroController.text = endereco.bairro;
      _cidadeController.text = endereco.cidade;
      _estadoController.text = endereco.estado;
    }
  }

  Future<void> _salvarEndereco() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvandoEndereco = true);

    try {
      final endereco = Endereco(
        cep: _cepController.text.trim(),
        rua: _ruaController.text.trim(),
        numero: _numeroController.text.trim(),
        complemento: _complementoController.text.trim().isEmpty ? null : _complementoController.text.trim(),
        bairro: _bairroController.text.trim(),
        cidade: _cidadeController.text.trim(),
        estado: _estadoController.text.trim(),
      );

      await ref.read(authControllerProvider.notifier).atualizarPerfil(endereco: endereco);

      if (mounted) {
        SnackBarUtils.mostrarSucesso(context, 'Endereço salvo com sucesso!');
        ref.invalidate(usuarioAtualStreamProvider); // Refresh user data
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.mostrarErro(context, 'Erro ao salvar endereço: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _salvandoEndereco = false);
      }
    }
  }

  void _mostrarDialogoSucesso() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Expanded(child: Text('Em análise!')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Aguardando aprovação do sistema',
                      style: TextStyle(color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              '⏱️ Prazo: até 48 horas\n'
              '📧 Você será notificado por email\n'
              '🔔 E receberá uma notificação no app',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'A verificação aumenta sua credibilidade e pode trazer mais oportunidades!',
                      style: TextStyle(fontSize: 13, color: Colors.green.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fecha diálogo
              Navigator.of(context).pop(); // Volta para home
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text('Entendi, ir para Home'),
          ),
        ],
      ),
    );
  }

  Future<void> _selecionarComprovante() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imagem = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (imagem != null) {
      setState(() {
        _comprovanteImagem = File(imagem.path);
      });
    }
  }

  Future<void> _tirarFotoComprovante() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imagem = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (imagem != null) {
      setState(() {
        _comprovanteImagem = File(imagem.path);
      });
    }
  }

  Future<void> _enviarComprovante() async {
    if (_comprovanteImagem == null) {
      SnackBarUtils.mostrarErro(context, 'Selecione um comprovante de residência');
      return;
    }

    final usuarioAsync = ref.read(usuarioAtualStreamProvider);
    final usuario = usuarioAsync.value;

    if (usuario == null || usuario.endereco == null) {
      SnackBarUtils.mostrarErro(context, 'Endereço não encontrado no perfil');
      return;
    }

    setState(() => _enviando = true);

    try {
      await ref.read(verificacaoResidenciaProvider.notifier).solicitarVerificacao(
        usuarioId: usuario.id,
        comprovante: _comprovanteImagem!,
      );
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usuarioAsync = ref.watch(usuarioAtualStreamProvider);

    // Observar mudanças no estado da verificação
    ref.listen<AsyncValue<VerificacaoResidencia?>>(verificacaoResidenciaProvider, (previous, next) {
      if (next.hasError) {
        final errorMessage = next.error is AppException ? (next.error as AppException).message : next.error.toString();
        SnackBarUtils.mostrarErro(context, errorMessage);
      } else if (next.hasValue && previous?.isLoading == true) {
        // Sucesso - transição de loading para data
        _mostrarDialogoSucesso();
      }
    });

    // Adicionar estado de loading para evitar rebuilds desnecessários
    if (usuarioAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Verificar Residência'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final usuario = usuarioAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprovante de Residência'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner de aviso se endereço reprovado
            if (usuario?.statusEndereco == StatusEndereco.rejeitado) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade300, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Solicitação Recusada',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.red.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sua solicitação de verificação foi recusada. Por favor, envie um novo comprovante de residência.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Banner informativo
            if (usuario?.statusEndereco != StatusEndereco.emAnalise)
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
                        'Esta verificação é opcional, mas aumenta sua confiabilidade na plataforma.',
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
            
            // Banner de em análise
            if (usuario?.statusEndereco == StatusEndereco.emAnalise)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade300, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_empty, color: Colors.orange.shade700, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Em Análise',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Seu comprovante está sendo analisado. Você já pode acessar a plataforma, mas algumas ações estarão limitadas até a aprovação.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            usuario?.endereco == null ? _buildFormularioEndereco() : _buildFormularioComprovante(usuario!),
          ],
        ),
      ),
    );
  }

  Widget _buildFormularioEndereco() {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Informações 
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.home, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Cadastro de Endereço',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Primeiro, cadastre seu endereço completo. Depois você poderá enviar o comprovante de residência.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Campos de endereço
          TextFormField(
            controller: _cepController,
            decoration: const InputDecoration(
              labelText: 'CEP',
              hintText: '00000-000',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              // Add CEP formatter if needed
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'CEP é obrigatório';
              }
              if (value.length != 8 && value.length != 9) {
                return 'CEP inválido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ruaController,
            decoration: const InputDecoration(
              labelText: 'Rua',
              hintText: 'Nome da rua',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Rua é obrigatória';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _numeroController,
                  decoration: const InputDecoration(
                    labelText: 'Número',
                    hintText: '123',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Número é obrigatório';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _complementoController,
                  decoration: const InputDecoration(
                    labelText: 'Complemento',
                    hintText: 'Apto, bloco, etc.',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bairroController,
            decoration: const InputDecoration(
              labelText: 'Bairro',
              hintText: 'Nome do bairro',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Bairro é obrigatório';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cidadeController,
                  decoration: const InputDecoration(
                    labelText: 'Cidade',
                    hintText: 'Nome da cidade',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Cidade é obrigatória';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _estadoController,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    hintText: 'UF',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Estado é obrigatório';
                    }
                    if (value.length != 2) {
                      return 'Use a sigla do estado';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _salvandoEndereco ? null : _salvarEndereco,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: _salvandoEndereco
                ? const CircularProgressIndicator()
                : const Text('Salvar Endereço'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormularioComprovante(Usuario usuario) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Informações
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Sobre a verificação',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Para aumentar a segurança da plataforma, solicitamos um comprovante de residência.\n\n'
                  'Documentos aceitos:\n'
                  '• Conta de luz, água ou gás\n'
                  '• Contrato de aluguel\n'
                  '• Extrato bancário\n'
                  '• Declaração de imposto de renda\n\n'
                  'O documento deve ser recente (últimos 3 meses) e conter seu nome e endereço completo.',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Endereço a ser verificado
        Card(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Endereço cadastrado:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${usuario.endereco!.rua}, ${usuario.endereco!.numero}',
                  style: theme.textTheme.bodyMedium,
                ),
                if (usuario.endereco!.complemento != null) ...[
                  Text(
                    usuario.endereco!.complemento!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
                Text(
                  '${usuario.endereco!.bairro} - ${usuario.endereco!.cidade}/${usuario.endereco!.estado}',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  'CEP: ${usuario.endereco!.cep}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),

        // Preview do comprovante
        if (_comprovanteImagem != null) ...[
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Image.file(
                  _comprovanteImagem!,
                  fit: BoxFit.cover,
                  height: 300,
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _comprovanteImagem = null);
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Remover'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Botões de ação
        if (_comprovanteImagem == null) ...[
          ElevatedButton.icon(
            onPressed: _selecionarComprovante,
            icon: const Icon(Icons.photo_library),
            label: const Text('Selecionar da Galeria'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _tirarFotoComprovante,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Tirar Foto'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ] else ...[
          ElevatedButton.icon(
            onPressed: _enviando ? null : _enviarComprovante,
            icon: _enviando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(_enviando ? 'Enviando...' : 'Enviar para Análise'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Aviso
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber),
          ),
          child: Row(
            children: [
              const Icon(Icons.schedule, color: Colors.amber, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'A análise do comprovante pode levar até 48 horas. Você será notificado assim que for aprovado.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
