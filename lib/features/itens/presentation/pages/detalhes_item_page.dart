import 'package:coisarapida/features/favoritos/providers/favoritos_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../alugueis/presentation/widgets/seletor_datas.dart';
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
  
  // Dados mockados do item (em produção viria do provider)
  late Map<String, dynamic> _item;

  @override
  void initState() {
    super.initState();
    _carregarItem();
  }

  void _carregarItem() {
    // Simular carregamento do item
    _item = {
      'id': widget.itemId,
      'nome': 'Furadeira Bosch Professional',
      'categoria': 'ferramentas',
      'descricao': 'Furadeira de impacto profissional Bosch GSB 13 RE, 650W, com maleta e acessórios. Ideal para furos em alvenaria, madeira e metal. Estado de conservação excelente, pouco uso.',
      'precoPorDia': 15.0,
      'precoPorHora': 3.0,
      'caucao': 50.0,
      'regrasUso': 'Não usar em dias chuvosos. Devolver limpa e com todos os acessórios. Responsabilidade por danos.',
      'fotos': [
        'https://via.placeholder.com/400x300?text=Furadeira+1',
        'https://via.placeholder.com/400x300?text=Furadeira+2',
        'https://via.placeholder.com/400x300?text=Furadeira+3',
      ],
      'disponivel': true,
      'aprovacaoAutomatica': false,
      'proprietarioId': 'user1',
      'proprietarioNome': 'João Silva',
      'proprietarioFoto': 'https://via.placeholder.com/100x100?text=JS',
      'proprietarioReputacao': 4.8,
      'proprietarioTotalAlugueis': 23,
      'distancia': 0.8,
      'avaliacao': 4.8,
      'totalAlugueis': 12,
      'endereco': 'Rua das Flores, 123 - Centro',
      'cidade': 'São Paulo',
      'criadoEm': DateTime.now().subtract(const Duration(days: 15)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favoritosNotifier = ref.watch(favoritosProvider.notifier);
    final isFavorito = favoritosNotifier.isFavorito(widget.itemId);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar com fotos
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Carousel de fotos
                  PageView.builder(
                    onPageChanged: (index) {
                      setState(() => _fotoAtual = index);
                    },
                    itemCount: _item['fotos'].length,
                    itemBuilder: (context, index) => Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(_item['fotos'][index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  
                  // Indicador de fotos
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _item['fotos'].length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _fotoAtual == index 
                                ? Colors.white 
                                : Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Status de disponibilidade
                  Positioned(
                    top: 60,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _item['disponivel'] ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _item['disponivel'] ? 'Disponível' : 'Indisponível',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome e categoria
                  Text(
                    _item['nome'],
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _item['categoria'].toString().toUpperCase(),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Preços
                  Row(
                    children: [
                      Expanded(
                        child: _buildPrecoCard(
                          'Por Dia',
                          'R\$ ${_item['precoPorDia'].toStringAsFixed(2)}',
                          theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPrecoCard(
                          'Por Hora',
                          'R\$ ${_item['precoPorHora'].toStringAsFixed(2)}',
                          theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Informações do proprietário
                  _buildProprietarioCard(theme),
                  
                  const SizedBox(height: 20),
                  
                  // Descrição
                  Text(
                    'Descrição',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _item['descricao'],
                    style: theme.textTheme.bodyLarge,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Regras de uso
                  if (_item['regrasUso'] != null) ...[
                    Text(
                      'Regras de Uso',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _item['regrasUso'],
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // Informações adicionais
                  _buildInformacoesAdicionais(theme),
                  
                  const SizedBox(height: 20),
                  
                  // Localização
                  _buildLocalizacaoCard(theme),
                  
                  const SizedBox(height: 100), // Espaço para o botão fixo
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBotaoAluguel(theme),
    );
  }

  Widget _buildPrecoCard(String titulo, String preco, Color cor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: TextStyle(
              color: cor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            preco,
            style: TextStyle(
              color: cor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProprietarioCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(_item['proprietarioFoto']),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _item['proprietarioNome'],
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text('${_item['proprietarioReputacao']}'),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.handshake,
                        color: Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text('${_item['proprietarioTotalAlugueis']} aluguéis'),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  onPressed: () => _abrirChat(),
                  icon: const Icon(Icons.chat),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
                const Text('Chat', style: TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformacoesAdicionais(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações Adicionais',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildInfoRow('Caução', 'R\$ ${_item['caucao'].toStringAsFixed(2)}'),
            _buildInfoRow('Aprovação', _item['aprovacaoAutomatica'] ? 'Automática' : 'Manual'),
            _buildInfoRow('Total de aluguéis', '${_item['totalAlugueis']}'),
            _buildInfoRow('Avaliação', '${_item['avaliacao']} ⭐'),
            _buildInfoRow('Anunciado em', _formatarData(_item['criadoEm'])),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            valor,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalizacaoCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Localização',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(_item['endereco']),
            Text(_item['cidade']),
            const SizedBox(height: 8),
            Text(
              '${_item['distancia']} km de distância',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mapa em desenvolvimento',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotaoAluguel(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _abrirChat(),
                icon: const Icon(Icons.chat),
                label: const Text('Conversar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _item['disponivel'] 
                    ? () => _solicitarAluguel()
                    : null,
                icon: const Icon(Icons.calendar_today),
                label: Text(_item['disponivel'] ? 'Alugar Agora' : 'Indisponível'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirChat() {
    // Simular abertura do chat
    context.push('${AppRoutes.chat}/chat1');
  }

  void _solicitarAluguel() {
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
            precoPorDia: _item['precoPorDia'],
            precoPorHora: _item['precoPorHora'],
            permitirPorHora: true,
            onDatasChanged: (inicio, fim) {
              setState(() {
                _dataInicio = inicio;
                _dataFim = fim;
              });
              
              if (inicio != null && fim != null) {
                _confirmarSolicitacao(inicio, fim);
              }
            },
          ),
        ),
      ),
    );
  }

  void _confirmarSolicitacao(DateTime inicio, DateTime fim) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Solicitação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item: ${_item['nome']}'),
            Text('Proprietário: ${_item['proprietarioNome']}'),
            const SizedBox(height: 8),
            Text('Período: ${_formatarData(inicio)} até ${_formatarData(fim)}'),
            const SizedBox(height: 8),
            Text(
              'Valor total: ${_calcularValorTotal(inicio, fim)}',
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

  String _calcularValorTotal(DateTime inicio, DateTime fim) {
    final duracao = fim.difference(inicio);
    
    if (duracao.inHours < 24) {
      // Aluguel por horas
      final horas = duracao.inHours;
      final valor = horas * _item['precoPorHora'];
      return 'R\$ ${valor.toStringAsFixed(2)}';
    } else {
      // Aluguel por dias
      final dias = duracao.inDays + 1;
      final valor = dias * _item['precoPorDia'];
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
