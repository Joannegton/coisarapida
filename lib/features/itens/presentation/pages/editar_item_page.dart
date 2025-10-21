import 'package:flutter/material.dart';
import 'package:coisarapida/features/autenticacao/presentation/providers/auth_provider.dart';
import 'package:coisarapida/features/autenticacao/presentation/widgets/campo_texto_customizado.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/item.dart';
import '../providers/item_provider.dart';
import '../widgets/seletor_fotos.dart';
import '../widgets/dropdown_customizado.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../home/presentation/providers/itens_provider.dart';
import '../../../perfil/presentation/providers/perfil_publico_provider.dart';

class EditarItemPage extends ConsumerStatefulWidget {
  final String itemId;

  const EditarItemPage({super.key, required this.itemId});

  @override
  ConsumerState<EditarItemPage> createState() => _EditarItemPageState();
}

class _EditarItemPageState extends ConsumerState<EditarItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _precoDiaController = TextEditingController();
  final _precoVendaController = TextEditingController();
  final _precoHoraController = TextEditingController();
  final _caucaoController = TextEditingController();
  final _regrasController = TextEditingController();

  String _categoriaSelecionada = '';
  List<String> _fotosUrls = [];
  TipoItem _tipoItem = TipoItem.aluguel;
  EstadoItem _estadoItem = EstadoItem.usado;
  bool _aluguelPorHora = false;
  bool _aprovacaoAutomatica = false;
  bool _isLoading = true;
  bool _isSaving = false;
  Item? _itemOriginal;

  final List<Map<String, dynamic>> _categorias = [
    {'id': 'ferramentas', 'nome': 'Ferramentas', 'icone': Icons.build},
    {'id': 'eletronicos', 'nome': 'Eletrônicos', 'icone': Icons.devices},
    {'id': 'esportes', 'nome': 'Esportes', 'icone': Icons.sports_soccer},
    {'id': 'casa', 'nome': 'Casa & Jardim', 'icone': Icons.home},
    {'id': 'transporte', 'nome': 'Transporte', 'icone': Icons.directions_bike},
    {'id': 'eventos', 'nome': 'Eventos', 'icone': Icons.celebration},
    {'id': 'saude', 'nome': 'Saúde', 'icone': Icons.medical_services},
    {'id': 'outros', 'nome': 'Outros', 'icone': Icons.category},
  ];

  @override
  void initState() {
    super.initState();
    _carregarDadosItem();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nomeController.dispose();
    _descricaoController.dispose();
    _precoDiaController.dispose();
    _precoVendaController.dispose();
    _precoHoraController.dispose();
    _caucaoController.dispose();
    _regrasController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosItem() async {
    try {
      final itemAsync = await ref.read(detalhesItemProvider(widget.itemId).future);
      if (itemAsync != null) {
        _preencherCampos(itemAsync);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.mostrarErro(context, 'Erro ao carregar dados do item: $e');
        context.pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _preencherCampos(Item item) {
    _itemOriginal = item;
    _nomeController.text = item.nome;
    _descricaoController.text = item.descricao;
    _categoriaSelecionada = item.categoria;
    _fotosUrls = List.from(item.fotos);
    _tipoItem = item.tipo;
    _estadoItem = item.estado;
    _aluguelPorHora = item.precoPorHora != null;
    _aprovacaoAutomatica = item.aprovacaoAutomatica;

    _precoDiaController.text = item.precoPorDia.toString();
    if (item.precoPorHora != null) {
      _precoHoraController.text = item.precoPorHora.toString();
    }
    if (item.precoVenda != null) {
      _precoVendaController.text = item.precoVenda.toString();
    }
    if (item.valorCaucao != null) {
      _caucaoController.text = item.valorCaucao.toString();
    }
    if (item.regrasUso != null) {
      _regrasController.text = item.regrasUso!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Editar Item'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: theme.brightness == Brightness.light
              ? Brightness.dark
              : Brightness.light,
          statusBarIconBrightness: theme.brightness == Brightness.light
              ? Brightness.dark
              : Brightness.light,
        ),
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: const Text(
          'Editar Item',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _salvarAlteracoes,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Salvar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seletor de Fotos
              SeletorFotosWidget(
                fotosIniciais: _fotosUrls,
                onFotosChanged: (fotos) {
                  setState(() => _fotosUrls = fotos);
                },
                maxFotos: 5,
              ),
              const SizedBox(height: 24),

              // Nome
              CampoTextoCustomizado(
                controller: _nomeController,
                label: 'Nome do Item',
                hint: 'Digite o nome do item',
                prefixIcon: Icons.label_outlined,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nome é obrigatório';
                  }
                  if (value.length < 3) {
                    return 'Nome deve ter pelo menos 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Descrição
              CampoTextoCustomizado(
                controller: _descricaoController,
                label: 'Descrição',
                hint: 'Digite a descrição do item',
                maxLines: 3,
                prefixIcon: Icons.description_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Descrição é obrigatória';
                  }
                  if (value.length < 10) {
                    return 'Descrição deve ter pelo menos 10 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Categoria
              DropdownCustomizado<String>(
                label: 'Categoria',
                value: _categoriaSelecionada.isNotEmpty ? _categoriaSelecionada : null,
                prefixIcon: Icons.category,
                items: _categorias
                    .map((categoria) => DropdownItem<String>(
                          value: categoria['id'],
                          label: categoria['nome'],
                          child: Row(
                            children: [
                              Icon(categoria['icone'], size: 20),
                              const SizedBox(width: 8),
                              Text(categoria['nome']),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _categoriaSelecionada = value ?? '');
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Categoria é obrigatória';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tipo do Item
              DropdownCustomizado<TipoItem>(
                label: 'Tipo',
                value: _tipoItem,
                prefixIcon: Icons.local_shipping_outlined,
                items: [
                  DropdownItem(
                    value: TipoItem.aluguel,
                    label: 'Aluguel',
                  ),
                  DropdownItem(
                    value: TipoItem.venda,
                    label: 'Venda',
                  ),
                  DropdownItem(
                    value: TipoItem.ambos,
                    label: 'Aluguel e Venda',
                  ),
                ],
                onChanged: (value) {
                  setState(() => _tipoItem = value ?? TipoItem.aluguel);
                },
              ),
              const SizedBox(height: 16),

              // Estado do Item
              DropdownCustomizado<EstadoItem>(
                label: 'Estado',
                value: _estadoItem,
                prefixIcon: Icons.info_outlined,
                items: [
                  DropdownItem(
                    value: EstadoItem.novo,
                    label: 'Novo',
                  ),
                  DropdownItem(
                    value: EstadoItem.usado,
                    label: 'Usado',
                  ),
                  DropdownItem(
                    value: EstadoItem.seminovo,
                    label: 'Seminovo',
                  ),
                ],
                onChanged: (value) {
                  setState(() => _estadoItem = value ?? EstadoItem.usado);
                },
              ),
              const SizedBox(height: 16),

              // Preço por dia
              CampoTextoCustomizado(
                controller: _precoDiaController,
                label: 'Preço por Dia (R\$)',
                hint: 'Digite o preço por dia',
                prefixIcon: Icons.attach_money_outlined,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Preço por dia é obrigatório';
                  }
                  final preco = double.tryParse(value.replaceAll(',', '.'));
                  if (preco == null || preco <= 0) {
                    return 'Preço deve ser maior que zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Aluguel por hora
              SwitchListTile(
                title: const Text('Permitir aluguel por hora'),
                value: _aluguelPorHora,
                onChanged: (value) {
                  setState(() => _aluguelPorHora = value);
                },
              ),

              // Preço por hora (se aluguel por hora estiver ativado)
              if (_aluguelPorHora)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: CampoTextoCustomizado(
                    controller: _precoHoraController,
                    label: 'Preço por Hora (R\$)',
                    hint: 'Digite o preço por hora',
                    prefixIcon: Icons.schedule_outlined,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (_aluguelPorHora) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Preço por hora é obrigatório';
                        }
                        final preco = double.tryParse(value.replaceAll(',', '.'));
                        if (preco == null || preco <= 0) {
                          return 'Preço deve ser maior que zero';
                        }
                      }
                      return null;
                    },
                  ),
                ),

              // Preço de venda (se for venda ou ambos)
              if (_tipoItem == TipoItem.venda || _tipoItem == TipoItem.ambos)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: CampoTextoCustomizado(
                    controller: _precoVendaController,
                    label: 'Preço de Venda (R\$)',
                    hint: 'Digite o preço de venda',
                    prefixIcon: Icons.sell_outlined,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (_tipoItem == TipoItem.venda || _tipoItem == TipoItem.ambos) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Preço de venda é obrigatório';
                        }
                        final preco = double.tryParse(value.replaceAll(',', '.'));
                        if (preco == null || preco <= 0) {
                          return 'Preço deve ser maior que zero';
                        }
                      }
                      return null;
                    },
                  ),
                ),

              // Caução
              CampoTextoCustomizado(
                controller: _caucaoController,
                label: 'Valor da Caução (R\$) - Opcional',
                hint: 'Digite o valor da caução',
                prefixIcon: Icons.security_outlined,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Regras de uso
              CampoTextoCustomizado(
                controller: _regrasController,
                label: 'Regras de Uso - Opcional',
                hint: 'Digite as regras de uso do item',
                maxLines: 3,
                prefixIcon: Icons.rule_outlined,
              ),
              const SizedBox(height: 16),

              // Aprovação automática
              SwitchListTile(
                title: const Text('Aprovação automática de solicitações'),
                value: _aprovacaoAutomatica,
                onChanged: (value) {
                  setState(() => _aprovacaoAutomatica = value);
                },
              ),

              const SizedBox(height: 32),

              // Botão de salvar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _salvarAlteracoes,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Salvar Alterações',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              
              // Espaço adicional para evitar que o botão fique cortado
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_fotosUrls.isEmpty) {
      SnackBarUtils.mostrarErro(context, 'Adicione pelo menos uma foto do item.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final usuarioAtual = ref.read(usuarioAtualStreamProvider).value;
      if (usuarioAtual == null) {
        throw Exception('Usuário não autenticado');
      }

      if (_itemOriginal == null) {
        throw Exception('Item original não encontrado');
      }

      // Usar o controller para atualizar o item
      final controller = ref.read(itemControllerProvider.notifier);
      
      await controller.atualizarItem(
        itemId: widget.itemId,
        nome: _nomeController.text.trim(),
        descricao: _descricaoController.text.trim(),
        categoria: _categoriaSelecionada,
        fotosPaths: _fotosUrls,
        precoPorDia: double.tryParse(_precoDiaController.text.replaceAll(',', '.')) ?? 0.0,
        precoVenda: _tipoItem == TipoItem.venda || _tipoItem == TipoItem.ambos
            ? double.tryParse(_precoVendaController.text.replaceAll(',', '.'))
            : null,
        tipo: _tipoItem,
        estado: _estadoItem,
        precoPorHora: _aluguelPorHora ? double.tryParse(_precoHoraController.text.replaceAll(',', '.')) : null,
        caucao: double.tryParse(_caucaoController.text.replaceAll(',', '.')),
        regrasUso: _regrasController.text.trim().isNotEmpty ? _regrasController.text.trim() : null,
        aprovacaoAutomatica: _aprovacaoAutomatica,
        itemOriginal: _itemOriginal!,
      );

      // Invalidar o cache dos providers para recarregar os dados
      ref.invalidate(detalhesItemProvider(widget.itemId));
      
      // Invalidar também os providers de listagem para atualizar a home e busca
      ref.invalidate(todosItensStreamProvider);
      
      // Invalidar o perfil para atualizar os itens do usuário
      ref.invalidate(perfilPublicoDetalhadoProvider(usuarioAtual.id));
      
      // Limpar o cache de imagens para forçar o recarregamento das novas URLs
      if (mounted) {
        imageCache.clear();
        imageCache.clearLiveImages();
      }

      if (mounted) {
        SnackBarUtils.mostrarSucesso(context, 'Item atualizado com sucesso!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.mostrarErro(context, 'Erro ao salvar alterações: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
