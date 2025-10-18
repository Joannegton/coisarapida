import 'package:coisarapida/core/constants/app_routes.dart';
import 'package:coisarapida/features/itens/presentation/widgets/seletor_fotos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:coisarapida/core/utils/snackbar_utils.dart';
import 'package:coisarapida/core/errors/exceptions.dart';
import 'package:coisarapida/features/autenticacao/presentation/providers/auth_provider.dart';
import 'package:coisarapida/features/autenticacao/domain/entities/endereco.dart';
import 'package:coisarapida/features/autenticacao/domain/entities/usuario.dart';
import 'package:coisarapida/features/autenticacao/domain/entities/status_endereco.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../providers/seguranca_provider.dart';
import '../../domain/entities/verificacao_residencia.dart';

/// Página para verificação de residência
class VerificacaoResidenciaPage extends ConsumerStatefulWidget {
  const VerificacaoResidenciaPage({super.key});

  @override
  ConsumerState<VerificacaoResidenciaPage> createState() => _VerificacaoResidenciaPageState();
}

class _VerificacaoResidenciaPageState extends ConsumerState<VerificacaoResidenciaPage> {
  List<String> _fotosComprovante = [];
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

  bool _camposPreenchidos = false;

  bool _obtendoLocalizacao = false;

  bool _mostrarBotaoLocalizacao = true;
  bool _tentouPreencherLocalizacao = false;

  double? latitude;
  double? longitude;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_camposPreenchidos) {
      _preencherCamposEndereco();
      _camposPreenchidos = true;
    }
    if (!_tentouPreencherLocalizacao) {
      _tentarPreencherComLocalizacao();
      _tentouPreencherLocalizacao = true;
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
    final cepFormatado = _cepController.text.trim().replaceAll(RegExp(r'[^0-9]'), ''); 
    try {
      final endereco = Endereco(
        cep: cepFormatado,
        rua: _ruaController.text.trim(),
        numero: _numeroController.text.trim(),
        complemento: _complementoController.text.trim().isEmpty ? null : _complementoController.text.trim(),
        bairro: _bairroController.text.trim(),
        cidade: _cidadeController.text.trim(),
        estado: _estadoController.text.trim(),
        latitude: latitude,
        longitude: longitude,
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

  String? _obterSiglaEstado(String? administrativeArea) {
    if (administrativeArea == null) return null;

    const mapaEstados = {
      'Acre': 'AC',
      'Alagoas': 'AL',
      'Amapá': 'AP',
      'Amazonas': 'AM',
      'Bahia': 'BA',
      'Ceará': 'CE',
      'Distrito Federal': 'DF',
      'Espírito Santo': 'ES',
      'Goiás': 'GO',
      'Maranhão': 'MA',
      'Mato Grosso': 'MT',
      'Mato Grosso do Sul': 'MS',
      'Minas Gerais': 'MG',
      'Pará': 'PA',
      'Paraíba': 'PB',
      'Paraná': 'PR',
      'Pernambuco': 'PE',
      'Piauí': 'PI',
      'Rio de Janeiro': 'RJ',
      'Rio Grande do Norte': 'RN',
      'Rio Grande do Sul': 'RS',
      'Rondônia': 'RO',
      'Roraima': 'RR',
      'Santa Catarina': 'SC',
      'São Paulo': 'SP',
      'Sergipe': 'SE',
      'Tocantins': 'TO',
    };

    // Tentar encontrar pelo nome exato
    if (mapaEstados.containsKey(administrativeArea)) {
      return mapaEstados[administrativeArea];
    }

    // Tentar encontrar por nome parcial (para casos onde o geocoding retorna variações)
    for (final entry in mapaEstados.entries) {
      if (administrativeArea.toLowerCase().contains(entry.key.toLowerCase()) ||
          entry.key.toLowerCase().contains(administrativeArea.toLowerCase())) {
        return entry.value;
      }
    }

    // Se não encontrar, retornar o valor original (pode ser que já seja sigla)
    return administrativeArea.length == 2 ? administrativeArea.toUpperCase() : null;
  }

  Future<void> _tentarPreencherComLocalizacao() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        await _preencherComLocalizacaoAtual();
        setState(() => _mostrarBotaoLocalizacao = false);
      } else {
        setState(() => _mostrarBotaoLocalizacao = true);
      }
    } catch (e) {
      setState(() => _mostrarBotaoLocalizacao = true);
    }
  }

  Future<void> _preencherComLocalizacaoAtual() async {
    setState(() => _obtendoLocalizacao = true);

    try {
      // Verificar permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
          SnackBarUtils.mostrarErro(context, 'Permissão de localização negada');
          return;
      }

      if (permission == LocationPermission.deniedForever) {
        SnackBarUtils.mostrarErro(context, 'Permissão de localização negada permanentemente. Habilite nas configurações.');
        return;
      }

      // Obter posição atual
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      latitude = position.latitude;
      longitude = position.longitude;

      // Reverse geocoding
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        final sigla = place.administrativeArea != null
            ? _obterSiglaEstado(place.administrativeArea)
            : null;

        final isPlusCode = RegExp(r'^[A-Z0-9]{4}\+[A-Z0-9]{4}').hasMatch(place.street ?? '');

        setState(() {
          _cepController.text = place.postalCode ?? '';
          _ruaController.text = isPlusCode ? '' : place.street ?? '';
          _numeroController.text = '';
          _complementoController.text = '';
          _bairroController.text = place.subLocality ?? place.locality ?? '';
          _cidadeController.text = place.subAdministrativeArea ?? '';
          _estadoController.text = sigla ?? '';
        });

      } else {
        SnackBarUtils.mostrarErro(context, 'Não foi possível obter o endereço da localização');
      }
    } catch (e) {
      SnackBarUtils.mostrarErro(context, 'Erro ao obter localização');
    } finally {
      if (mounted) {
        setState(() => _obtendoLocalizacao = false);
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
              context.go(AppRoutes.home);
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

  Future<void> _enviarComprovante() async {
    if (_fotosComprovante.isEmpty) {
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
        comprovante: File(_fotosComprovante.first),
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
                            'Sua verificação foi recusada. Por favor, envie um novo comprovante.',
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
            ],
            
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
          // Botão para preencher com localização atual
          if (_mostrarBotaoLocalizacao)
            OutlinedButton.icon(
              onPressed: _obtendoLocalizacao ? null : _preencherComLocalizacaoAtual,
              icon: _obtendoLocalizacao
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(_obtendoLocalizacao ? 'Obtendo localização...' : 'Preencher com minha localização'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          const SizedBox(height: 16),
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

        // Seletor de fotos do comprovante
        SeletorFotosWidget(
          fotosIniciais: _fotosComprovante,
          onFotosChanged: (fotos) {
            setState(() {
              _fotosComprovante = fotos;
            });
          },
          maxFotos: 1,
          ehComprovante: true,
        ),

        if (_fotosComprovante.isNotEmpty) const SizedBox(height: 20),

        // Botão de enviar
        ElevatedButton.icon(
          onPressed: (_enviando || _fotosComprovante.isEmpty) ? null : _enviarComprovante,
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
    );
  }
}
