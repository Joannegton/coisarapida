import 'package:flutter/material.dart';
import 'package:coisarapida/features/autenticacao/presentation/providers/auth_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/item.dart';
import '../providers/item_provider.dart';
import '../widgets/seletor_fotos.dart';
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
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Item',
                  border: OutlineInputBorder(),
                ),
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
              TextFormField(
                controller: _descricaoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
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
              DropdownButtonFormField<String>(
                value: _categoriaSelecionada.isNotEmpty ? _categoriaSelecionada : null,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(),
                ),
                items: _categorias.map((categoria) {
                  return DropdownMenuItem<String>(
                    value: categoria['id'],
                    child: Row(
                      children: [
                        Icon(categoria['icone'], size: 20),
                        const SizedBox(width: 8),
                        Text(categoria['nome']),
                      ],
                    ),
                  );
                }).toList(),
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
              DropdownButtonFormField<TipoItem>(
                value: _tipoItem,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: TipoItem.aluguel,
                    child: const Text('Aluguel'),
                  ),
                  DropdownMenuItem(
                    value: TipoItem.venda,
                    child: const Text('Venda'),
                  ),
                  DropdownMenuItem(
                    value: TipoItem.ambos,
                    child: const Text('Aluguel e Venda'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _tipoItem = value ?? TipoItem.aluguel);
                },
              ),
              const SizedBox(height: 16),

              // Estado do Item
              DropdownButtonFormField<EstadoItem>(
                value: _estadoItem,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: EstadoItem.novo,
                    child: const Text('Novo'),
                  ),
                  DropdownMenuItem(
                    value: EstadoItem.usado,
                    child: const Text('Usado'),
                  ),
                  DropdownMenuItem(
                    value: EstadoItem.seminovo,
                    child: const Text('Seminovo'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _estadoItem = value ?? EstadoItem.usado);
                },
              ),
              const SizedBox(height: 16),

              // Preço por dia
              TextFormField(
                controller: _precoDiaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Preço por Dia (R\$)',
                  border: OutlineInputBorder(),
                ),
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
                  child: TextFormField(
                    controller: _precoHoraController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Preço por Hora (R\$)',
                      border: OutlineInputBorder(),
                    ),
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
                  child: TextFormField(
                    controller: _precoVendaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Preço de Venda (R\$)',
                      border: OutlineInputBorder(),
                    ),
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
              TextFormField(
                controller: _caucaoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valor da Caução (R\$) - Opcional',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Regras de uso
              TextFormField(
                controller: _regrasController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Regras de Uso - Opcional',
                  border: OutlineInputBorder(),
                ),
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
