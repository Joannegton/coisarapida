import 'package:coisarapida/core/constants/app_routes.dart';
import 'package:coisarapida/features/itens/presentation/providers/meus_itens_provider.dart';
import 'package:coisarapida/features/itens/presentation/providers/item_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MeusItensPage extends ConsumerStatefulWidget {
  const MeusItensPage({super.key});

  @override
  ConsumerState<MeusItensPage> createState() => _MeusItensPageState();
}

class _MeusItensPageState extends ConsumerState<MeusItensPage> {
  String _filtroCategoria = 'todos';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final meusItensState = ref.watch(meusItensProvider);

    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: theme.brightness == Brightness.light
              ? Brightness.dark
              : Brightness.light,
          statusBarIconBrightness: theme.brightness == Brightness.light
              ? Brightness.dark
              : Brightness.light,
        ),
        title: const Text('Meus Itens'),
        actions: [
          IconButton(
            icon: Icon(Icons.add, size: screenWidth * 0.06),
            onPressed: () => context.push(AppRoutes.anunciarItem),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: screenWidth * 0.15,
            padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              children: [
                _buildFiltroChip('todos', 'Todos'),
                _buildFiltroChip('ferramentas', 'Ferramentas'),
                _buildFiltroChip('eletronicos', 'Eletrônicos'),
                _buildFiltroChip('esportes', 'Esportes'),
                _buildFiltroChip('casa', 'Casa'),
              ],
            ),
          ),
          Expanded(
            child: meusItensState.when(
              data: (itens) {
                final itensFiltrados = _filtrarItens(itens);
                if (itensFiltrados.isEmpty) {
                  return Center(child: Text('Você ainda não publicou itens.'));
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(meusItensProvider);
                    await ref.read(meusItensProvider.future);
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    itemCount: itensFiltrados.length,
                    itemBuilder: (context, index) =>
                        _buildItemCard(context, theme, itensFiltrados[index]),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                  child:
                      Text('Erro ao carregar seus itens: ${error.toString()}')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(String categoria, String label) {
    final isSelected = _filtroCategoria == categoria;
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.only(right: screenWidth * 0.02),
      child: FilterChip(
        selected: isSelected,
        onSelected: (_) => setState(() => _filtroCategoria = categoria),
        label: Text(label),
        backgroundColor: isSelected ? theme.colorScheme.primary : null,
        selectedColor: theme.colorScheme.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : null,
          fontSize: screenWidth * 0.03,
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filtrarItens(List<Map<String, dynamic>> itens) {
    if (_filtroCategoria == 'todos') return itens;
    return itens
        .where((i) =>
            (i['categoria'] ?? '').toString().toLowerCase() ==
            _filtroCategoria.toLowerCase())
        .toList();
  }

  Widget _buildItemCard(
      BuildContext context, ThemeData theme, Map<String, dynamic> item) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Card(
      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
      child: InkWell(
        onTap: () => context.push('${AppRoutes.detalhesItem}/${item['id']}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.03),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: screenWidth * 0.2,
                  height: screenWidth * 0.2,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    image: item['fotos'] != null && item['fotos'].isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(item['fotos'][0]),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: item['fotos'] == null || item['fotos'].isEmpty
                      ? Icon(
                          Icons.image,
                          size: screenWidth * 0.08,
                          color: Colors.grey.shade400,
                        )
                      : null,
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['nome'] ?? 'Item sem nome',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.045,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: screenWidth * 0.01),
                    Text(
                      'Publicado em ${item['criadoEm'] != null ? (item['criadoEm'] is DateTime ? (item['criadoEm'] as DateTime).toLocal().toString().split(' ').first : item['criadoEm'].toString()) : '-'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'R\$ ${((item['precoPorDia'] ?? 0.0) as num).toDouble().toStringAsFixed(2)} /dia',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.04,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.02),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon:
                            Icon(Icons.edit_outlined, size: screenWidth * 0.06),
                        onPressed: () => context
                            .push('${AppRoutes.editarItem}/${item['id']}'),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            size: screenWidth * 0.06,
                            color: Colors.red.shade400),
                        onPressed: () =>
                            _confirmarDesativar(context, item['id']),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmarDesativar(BuildContext context, String itemId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desativar item'),
        content: const Text(
            'Deseja desativar este item? Ele ficará indisponível para locações.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(itemRepositoryProvider).desativarItem(itemId);
                ref.invalidate(meusItensProvider);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: ${e.toString()}')));
              }
            },
            child: const Text('Desativar'),
          ),
        ],
      ),
    );
  }
}
