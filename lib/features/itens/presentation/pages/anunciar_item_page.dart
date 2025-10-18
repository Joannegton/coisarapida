import 'package:coisarapida/features/autenticacao/domain/entities/endereco.dart';
import 'package:coisarapida/features/itens/presentation/widgets/categorias.dart';
import 'package:coisarapida/features/itens/presentation/widgets/sessao_informacoes.dart';
import 'package:coisarapida/features/itens/presentation/widgets/sessao_fotos.dart';
import 'package:coisarapida/features/itens/presentation/widgets/sessao_precos.dart';
import 'package:flutter/material.dart';
import 'package:coisarapida/features/autenticacao/presentation/providers/auth_provider.dart';
import 'package:coisarapida/core/utils/verificacao_helper.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/item.dart';
import '../providers/item_provider.dart';
import '../../../../core/utils/snackbar_utils.dart';

class AnunciarItemPage extends ConsumerStatefulWidget {
  const AnunciarItemPage({super.key});

  @override
  ConsumerState<AnunciarItemPage> createState() => _AnunciarItemPageState();
}

class _AnunciarItemPageState extends ConsumerState<AnunciarItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _precoDiaController = TextEditingController();
  final _precoVendaController = TextEditingController();
  final _precoHoraController = TextEditingController();
  final _caucaoController = TextEditingController();
  final _regrasController = TextEditingController();

  // Estado para os novos campos
  int _paginaAtual = 0;
  String _categoriaSelecionada = '';
  List<String> _fotosUrls = [];
  TipoItem _tipoItem = TipoItem.aluguel;
  EstadoItem _estadoItem = EstadoItem.usado;
  bool _aluguelPorHora = false;
  bool _aprovacaoAutomatica = false;

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
    _nomeController.addListener(_atualizarEstadoBotao);
    _descricaoController.addListener(_atualizarEstadoBotao);
    _precoDiaController.addListener(_atualizarEstadoBotao);
    _precoVendaController.addListener(_atualizarEstadoBotao);
    _precoHoraController.addListener(_atualizarEstadoBotao);
    _caucaoController.addListener(_atualizarEstadoBotao);
  }

  @override
  void dispose() {
    _nomeController.removeListener(_atualizarEstadoBotao);
    _descricaoController.removeListener(_atualizarEstadoBotao);
    _precoDiaController.removeListener(_atualizarEstadoBotao);
    _precoVendaController.removeListener(_atualizarEstadoBotao);
    _precoHoraController.removeListener(_atualizarEstadoBotao);
    _caucaoController.removeListener(_atualizarEstadoBotao);

    _nomeController.dispose();
    _descricaoController.dispose();
    _precoDiaController.dispose();
    _precoVendaController.dispose();
    _precoHoraController.removeListener(_atualizarEstadoBotao);
    _caucaoController.removeListener(_atualizarEstadoBotao);
    super.dispose();
  }

  void _atualizarEstadoBotao() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: theme.brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
          statusBarIconBrightness: theme.brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
        ),
        title: const Text('Anunciar Item'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_paginaAtual + 1) / 4,
            backgroundColor: Colors.grey.shade300,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: PageView(
          controller: _pageController,
          physics: _isBotaoProximoHabilitado()
              ? const AlwaysScrollableScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          onPageChanged: (pagina) {
            setState(() {
              _paginaAtual = pagina;
            });
          },
          children: [
            InformacoesSection(
                nomeController: _nomeController,
                descricaoController: _descricaoController,
                regrasController: _regrasController),
            CategoriasSection(
              categorias: _categorias,
              categoriaSelecionada: _categoriaSelecionada,
              onCategoriaSelecionada: (idCategoria) {
                setState(() => _categoriaSelecionada = idCategoria);
              },
            ),
            SessaoFotos(
              fotosUrls: _fotosUrls,
              onFotosChanged: (fotos) {
                setState(() {
                  _fotosUrls = fotos;
                });
              },
              maxFotos: 5,
            ),
            SessaoPrecos(
              precoDiaController: _precoDiaController,
              precoVendaController: _precoVendaController,
              precoHoraController: _precoHoraController,
              caucaoController: _caucaoController,
              tipoItem: _tipoItem,
              onTipoItemChanged: (valor) {
                if (valor != null) {
                  setState(() => _tipoItem = valor);
                }
              },
              estadoItem: _estadoItem,
              onEstadoItemChanged: (valor) {
                if (valor != null) setState(() => _estadoItem = valor);
              },
              aluguelPorHora: _aluguelPorHora,
              aprovacaoAutomatica: _aprovacaoAutomatica,
              onAluguelPorHoraChanged: (valor) {
                setState(() => _aluguelPorHora = valor);
              },
              onAprovacaoAutomaticaChanged: (valor) {
                setState(() => _aprovacaoAutomatica = valor);
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBotoesNavegacao(theme),
    );
  }

  Widget _buildBotoesNavegacao(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_paginaAtual > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _voltarPagina,
                child: const Text('Voltar'),
              ),
            ),
          if (_paginaAtual > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isBotaoProximoHabilitado()
                  ? (_paginaAtual == 3 ? _publicarItem : _proximaPagina)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                disabledBackgroundColor:
                    theme.colorScheme.primary.withAlpha(153),
                foregroundColor: theme.colorScheme.onPrimary,
                disabledForegroundColor:
                    theme.colorScheme.onPrimary.withAlpha(153),
              ),
              child: Text(_paginaAtual == 3 ? 'Publicar Item' : 'Próximo'),
            ),
          ),
        ],
      ),
    );
  }

  bool _isBotaoProximoHabilitado() {
    if (_paginaAtual == 0)
      return _nomeController.text.isNotEmpty &&
          _descricaoController.text.isNotEmpty;

    if (_paginaAtual == 1) return _categoriaSelecionada.isNotEmpty;

    if (_paginaAtual == 2) return _fotosUrls.isNotEmpty;

    if (_paginaAtual == 3) {
      final isAluguelValido =
          (_tipoItem == TipoItem.aluguel || _tipoItem == TipoItem.ambos) &&
              _precoDiaController.text.isNotEmpty;
      final isVendaValida =
          (_tipoItem == TipoItem.venda || _tipoItem == TipoItem.ambos) &&
              _precoVendaController.text.isNotEmpty;

      if (_tipoItem == TipoItem.ambos) return isAluguelValido && isVendaValida;
      if (_tipoItem == TipoItem.aluguel) return isAluguelValido;
      if (_tipoItem == TipoItem.venda) return isVendaValida;
    }

    return true;
  }

  void _voltarPagina() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _proximaPagina() {
    if (_validarPaginaAtualVisualmente()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validarPaginaAtualVisualmente() {
    switch (_paginaAtual) {
      case 0:
        return true;
      case 1:
        if (_categoriaSelecionada.isEmpty) {
          SnackBarUtils.mostrarErro(context, 'Selecione uma categoria');
          return false;
        }
        return true;
      case 2:
        if (_fotosUrls.isEmpty) {
          SnackBarUtils.mostrarErro(context, 'Adicione pelo menos uma foto');
          return false;
        }
        return true;
      case 3:
        if ((_tipoItem == TipoItem.aluguel || _tipoItem == TipoItem.ambos) &&
            _precoDiaController.text.isEmpty) {
          SnackBarUtils.mostrarErro(context, 'Preço por dia é obrigatório');
          return false;
        }
        if ((_tipoItem == TipoItem.venda || _tipoItem == TipoItem.ambos) &&
            _precoVendaController.text.isEmpty) {
          SnackBarUtils.mostrarErro(
              context, 'Preço de venda é obrigatório para venda');
          return false;
        }
        if (_aluguelPorHora && _precoHoraController.text.isEmpty) {
          SnackBarUtils.mostrarErro(
              context, 'Preço por hora é obrigatório se a opção estiver ativa');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _publicarItem() {
    // Verificar se usuário está 100% verificado
    if (!VerificacaoHelper.usuarioVerificado(ref)) {
      VerificacaoHelper.mostrarDialogVerificacao(context, ref);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      SnackBarUtils.mostrarErro(context,
          'Preencha corretamente todos os campos obrigatórios (marcados em vermelho).');
      if (_nomeController.text.trim().isEmpty ||
          _descricaoController.text.trim().isEmpty) {
        _pageController.jumpToPage(0);
      } else if (((_tipoItem == TipoItem.aluguel ||
                  _tipoItem == TipoItem.ambos) &&
              _precoDiaController.text.trim().isEmpty) ||
          ((_tipoItem == TipoItem.venda || _tipoItem == TipoItem.ambos) &&
              _precoVendaController.text.trim().isEmpty)) {
        _pageController.jumpToPage(3);
      }
      return;
    }

    if (_categoriaSelecionada.isEmpty) {
      SnackBarUtils.mostrarErro(
          context, 'Selecione uma categoria para o item.');
      _pageController.jumpToPage(1);
      return;
    }

    if (_fotosUrls.isEmpty) {
      SnackBarUtils.mostrarErro(
          context, 'Adicione pelo menos uma foto do item.');
      _pageController.jumpToPage(2);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Publicando item...'),
          ],
        ),
      ),
    );

    Endereco localizacao;
    final currentUser = ref.read(usuarioAtualStreamProvider).asData?.value;

    final enderecoUsuario = currentUser!.endereco!;

    localizacao = Endereco(
      latitude: enderecoUsuario.latitude ?? 0.0,
      longitude: enderecoUsuario.longitude ?? 0.0,
      bairro: enderecoUsuario.bairro,
      cidade: enderecoUsuario.cidade,
      estado: enderecoUsuario.estado,
      rua: enderecoUsuario.rua,
      numero: enderecoUsuario.numero,
      complemento: enderecoUsuario.complemento,
      cep: enderecoUsuario.cep,
    );

    ref
        .read(itemControllerProvider.notifier)
        .publicarItem(
          nome: _nomeController.text.trim(),
          descricao: _descricaoController.text.trim(),
          categoria: _categoriaSelecionada,
          fotosPaths: _fotosUrls,
          tipo: _tipoItem,
          estado: _estadoItem,
          precoPorDia: double.tryParse(_precoDiaController.text) ?? 0.0,
          precoVenda: double.tryParse(_precoVendaController.text),
          precoPorHora: _aluguelPorHora
              ? (double.tryParse(_precoHoraController.text) ?? 0.0)
              : null,
          caucao: double.tryParse(_caucaoController.text),
          regrasUso: _regrasController.text.trim(),
          aprovacaoAutomatica: _aprovacaoAutomatica,
          localizacao: localizacao,
        )
        .then((_) {
      Navigator.of(context).pop();
      SnackBarUtils.mostrarSucesso(context, 'Item publicado com sucesso! 🎉');
      context.pop();
    }).catchError((error) {
      print('Erro ao publicar item: $error');
      Navigator.of(context).pop();
      SnackBarUtils.mostrarErro(
          context, 'Erro ao publicar item: ${error.toString()}');
    });
  }
}
