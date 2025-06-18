import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tela para acompanhar entrega
class AcompanharEntregaPage extends ConsumerStatefulWidget {
  final String entregaId;
  
  const AcompanharEntregaPage({
    super.key,
    required this.entregaId,
  });

  @override
  ConsumerState<AcompanharEntregaPage> createState() => _AcompanharEntregaPageState();
}

class _AcompanharEntregaPageState extends ConsumerState<AcompanharEntregaPage> {
  final List<Map<String, dynamic>> _statusEntrega = [
    {
      'titulo': 'Pedido Confirmado',
      'descricao': 'Sua entrega foi confirmada e está sendo preparada',
      'hora': '14:30',
      'concluido': true,
      'icone': Icons.check_circle,
    },
    {
      'titulo': 'Entregador Designado',
      'descricao': 'João Silva foi designado para sua entrega',
      'hora': '14:45',
      'concluido': true,
      'icone': Icons.person,
    },
    {
      'titulo': 'Coletado',
      'descricao': 'Item coletado no endereço de origem',
      'hora': '15:20',
      'concluido': true,
      'icone': Icons.inventory,
    },
    {
      'titulo': 'Em Trânsito',
      'descricao': 'Entregador a caminho do destino',
      'hora': '15:35',
      'concluido': true,
      'icone': Icons.local_shipping,
    },
    {
      'titulo': 'Entregue',
      'descricao': 'Item entregue com sucesso',
      'hora': '--:--',
      'concluido': false,
      'icone': Icons.done_all,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Entrega ${widget.entregaId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _compartilharRastreamento,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Mapa (placeholder)
            _buildMapaPlaceholder(theme),
            
            // Informações do entregador
            _buildInfoEntregador(theme),
            
            // Status da entrega
            _buildStatusEntrega(theme),
            
            // Detalhes da entrega
            _buildDetalhesEntrega(theme),
          ],
        ),
      ),
      bottomNavigationBar: _buildBotoesAcao(theme),
    );
  }

  Widget _buildMapaPlaceholder(ThemeData theme) {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Center(
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
                  'Mapa em tempo real',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Em desenvolvimento',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Em Trânsito',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoEntregador(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Icon(
                Icons.person,
                color: theme.colorScheme.primary,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'João Silva',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.orange,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text('4.8'),
                      SizedBox(width: 16),
                      Icon(
                        Icons.local_shipping,
                        color: Colors.grey,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text('Moto'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tempo estimado: 15 minutos',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  onPressed: _ligarEntregador,
                  icon: const Icon(Icons.phone),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green.withOpacity(0.1),
                    foregroundColor: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                IconButton(
                  onPressed: _chatEntregador,
                  icon: const Icon(Icons.chat),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusEntrega(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status da Entrega',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _statusEntrega.length,
              itemBuilder: (context, index) {
                final status = _statusEntrega[index];
                final isLast = index == _statusEntrega.length - 1;
                
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: status['concluido']
                                ? theme.colorScheme.primary
                                : Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            status['icone'],
                            color: status['concluido']
                                ? Colors.white
                                : Colors.grey.shade600,
                            size: 20,
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 40,
                            color: status['concluido']
                                ? theme.colorScheme.primary
                                : Colors.grey.shade300,
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  status['titulo'],
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: status['concluido']
                                        ? null
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  status['hora'],
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              status['descricao'],
                              style: TextStyle(
                                color: status['concluido']
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade500,
                              ),
                            ),
                            if (!isLast) const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalhesEntrega(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalhes da Entrega',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildDetalheItem('Código', widget.entregaId),
            _buildDetalheItem('Tipo', 'Documento'),
            _buildDetalheItem('Urgência', 'Normal'),
            _buildDetalheItem('Valor', 'R\$ 8,00'),
            _buildDetalheItem('Origem', 'Rua das Flores, 123 - Centro'),
            _buildDetalheItem('Destino', 'Av. Paulista, 456 - Bela Vista'),
            _buildDetalheItem('Descrição', 'Documentos importantes'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalheItem(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(valor),
          ),
        ],
      ),
    );
  }

  Widget _buildBotoesAcao(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _cancelarEntrega,
              icon: const Icon(Icons.cancel, color: Colors.red),
              label: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _reportarProblema,
              icon: const Icon(Icons.report_problem),
              label: const Text('Reportar'),
            ),
          ),
        ],
      ),
    );
  }

  void _compartilharRastreamento() {
    // Implementar compartilhamento
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Compartilhamento em desenvolvimento'),
      ),
    );
  }

  void _ligarEntregador() {
    // Implementar ligação
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ligação em desenvolvimento'),
      ),
    );
  }

  void _chatEntregador() {
    // Implementar chat
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chat em desenvolvimento'),
      ),
    );
  }

  void _cancelarEntrega() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Entrega'),
        content: const Text(
          'Tem certeza que deseja cancelar esta entrega? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cancelamento em desenvolvimento'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sim, Cancelar'),
          ),
        ],
      ),
    );
  }

  void _reportarProblema() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reportar Problema'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Descreva o problema...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Problema reportado com sucesso!'),
                ),
              );
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }
}
