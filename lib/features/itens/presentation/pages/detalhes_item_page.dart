import 'package:coisarapida/features/favoritos/providers/favoritos_provider.dart';
import 'package:coisarapida/features/itens/domain/entities/item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../alugueis/presentation/widgets/seletor_datas.dart';
import '../providers/item_provider.dart'; // Para detalhesItemProvider
import '../widgets/detalhes_item_app_bar_content_widget.dart';
import '../widgets/detalhes_item_bottom_bar_widget.dart';
import '../widgets/detalhes_item_content_widget.dart';
import '../widgets/informacoes_adicionais_widget.dart';
import '../widgets/localizacao_card_widget.dart';
import '../widgets/proprietario_card_widget.dart';
import '../../../../core/constants/app_routes.dart';

/// Tela de detalhes do item com informações completas
class DetalhesItemPage extends ConsumerStatefulWidget {
  final String itemId;
  
  const DetalhesItemPage({
    super.key,
    required this.itemId,
  });

  @override
  ConsumerState<DetalhesItemPage> createState() => _DetalhesItemPageState();
}

class _DetalhesItemPageState extends ConsumerState<DetalhesItemPage> {
  int _fotoAtual = 0;
  DateTime? _dataInicio;
  DateTime? _dataFim;

  @override
  Widget build(BuildContext context) {
    final favoritosNotifier = ref.watch(favoritosProvider.notifier);
    final isFavorito = favoritosNotifier.isFavorito(widget.itemId);
    final itemAsyncValue = ref.watch(detalhesItemProvider(widget.itemId));
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar com fotos
          SliverAppBar(
            expandedHeight: 300,
            systemOverlayStyle: SystemUiOverlayStyle(
              // Mantém a cor da status bar transparente
              statusBarColor: Colors.transparent,
              // Ajusta o brilho dos ícones da status bar com base no tema atual
              // Se o tema do app for escuro, os ícones da status bar serão claros, e vice-versa.
              statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark ? Brightness.light : Brightness.dark,
            ),
            pinned: true,
            flexibleSpace: itemAsyncValue.when(
              data: (item) {
                if (item == null) {
                  return const Center(child: Text('Item não encontrado.'));
                }
                return DetalhesItemAppBarContentWidget(
                  item: item,
                  fotoAtual: _fotoAtual,
                  onPageChanged: (index) {
                    setState(() => _fotoAtual = index);
                  },
                );
              },
              loading: () => const FlexibleSpaceBar(background: Center(child: CircularProgressIndicator())),
              error: (error, stack) => FlexibleSpaceBar(background: Center(child: Text('Erro: $error'))),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isFavorito ? Icons.favorite : Icons.favorite_border,
                  color: isFavorito ? Colors.red : Colors.white,
                ),
                onPressed: () {
                  favoritosNotifier.toggleFavorito(widget.itemId);
                  SnackBarUtils.mostrarSucesso(
                    context,
                    isFavorito ? 'Removido dos favoritos' : 'Adicionado aos favoritos',
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () => SnackBarUtils.mostrarInfo(context, 'Compartilhar em desenvolvimento'),
              ),
            ],
          ),
          
          // Conteúdo
          itemAsyncValue.when(
            data: (item) {
              if (item == null) {
                return const SliverToBoxAdapter(child: Center(child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('Item não encontrado ou removido.'),
                )));
              }
              return SliverToBoxAdapter(
                child: DetalhesItemContentWidget(
                  item: item,
                  onChatPressed: () => _abrirChat(item.proprietarioId),
                  formatarData: _formatarData,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: Center(child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ))),
            error: (error, stack) => SliverToBoxAdapter(child: Center(child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('Erro ao carregar detalhes do item: $error'),
            ))),
          ),
        ],
      ),
      bottomNavigationBar: itemAsyncValue.maybeWhen(
        data: (item) => item != null
            ? DetalhesItemBottomBarWidget(
                item: item,
                onChatPressed: () => _abrirChat(item.proprietarioId),
                onAlugarPressed: () => _solicitarAluguel(item),
              )
            : null,
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }

  void _abrirChat(String proprietarioId) {
    // Simular abertura do chat
    // Idealmente, você passaria o ID do proprietário para a rota de chat
    context.push('${AppRoutes.chat}/$proprietarioId'); // Exemplo
  }

  void _solicitarAluguel(Item item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          child: SeletorDatas(
            dataInicio: _dataInicio,
            dataFim: _dataFim,
            precoPorDia: item.precoPorDia,
            precoPorHora: item.precoPorHora,
            permitirPorHora: item.precoPorHora != null && item.precoPorHora! > 0,
            onDatasChanged: (inicio, fim) {
              setState(() {
                _dataInicio = inicio;
                _dataFim = fim;
              });
              
              if (inicio != null && fim != null) {
                _confirmarSolicitacao(inicio, fim, item);
              }
            },
          ),
        ),
      ),
    );
  }

  void _confirmarSolicitacao(DateTime inicio, DateTime fim, Item item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Solicitação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item: ${item.nome}'),
            Text('Proprietário: ${item.proprietarioNome}'),
            const SizedBox(height: 8),
            Text('Período: ${_formatarData(inicio)} até ${_formatarData(fim)}'),
            const SizedBox(height: 8),
            Text(
              'Valor total: ${_calcularValorTotal(inicio, fim, item)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implementar lógica de envio da solicitação de aluguel
              SnackBarUtils.mostrarSucesso(
                context,
                'Solicitação enviada! Aguarde a aprovação.',
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  String _calcularValorTotal(DateTime inicio, DateTime fim, Item item) {
    final duracao = fim.difference(inicio);
    
    if (item.precoPorHora != null && item.precoPorHora! > 0 && duracao.inHours < 24) {
      // Aluguel por horas
      final horas = (duracao.inMinutes / 60).ceil(); // Arredonda para cima as horas
      final valor = horas * item.precoPorHora!;
      return 'R\$ ${valor.toStringAsFixed(2)}';
    } else {
      // Aluguel por dias
      // Adiciona 1 para incluir o dia final, se a diferença for exatamente em dias.
      // Se for 23h, conta como 1 dia. Se for 24h01m, conta como 2 dias.
      final dias = (duracao.inHours / 24).ceil();
      final valor = dias * item.precoPorDia;
      return 'R\$ ${valor.toStringAsFixed(2)}';
    }
  }

  String _formatarData(DateTime data) {
    final meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return '${data.day} ${meses[data.month - 1]} ${data.year}';
  }
}
