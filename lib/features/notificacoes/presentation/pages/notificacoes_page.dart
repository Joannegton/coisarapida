import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coisarapida/features/autenticacao/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class NotificacoesPage extends ConsumerStatefulWidget {
  const NotificacoesPage({super.key});

  @override
  ConsumerState<NotificacoesPage> createState() => _NotificacoesPageState();
}

class _NotificacoesPageState extends ConsumerState<NotificacoesPage> {
  @override
  void initState() {
    super.initState();
    // Limpar notificações antigas quando a página é aberta
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _limparNotificacoesAntigas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final usuarioId = ref.watch(usuarioAtualStreamProvider).value?.id;

    if (usuarioId == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () => _marcarTodasComoLidas(context, usuarioId),
            tooltip: 'Marcar todas como lidas',
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: () => _limparNotificacoesAntigas(),
            tooltip: 'Limpar notificações antigas',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notificacoes')
            .where('destinatarioId', isEqualTo: usuarioId)
            .orderBy('dataCriacao', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar notificações: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notificacoes = snapshot.data?.docs ?? [];

          if (notificacoes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Nenhuma notificação',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Suas notificações aparecerão aqui',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notificacoes.length,
            itemBuilder: (context, index) {
              final notificacao = notificacoes[index];
              final data = notificacao.data() as Map<String, dynamic>;

              return _buildNotificacaoItem(context, notificacao.id, data, ref);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificacaoItem(
    BuildContext context,
    String notificacaoId,
    Map<String, dynamic> data,
    WidgetRef ref,
  ) {
    final theme = Theme.of(context);
    final lida = data['lida'] ?? false;
    final tipo = data['tipo'] ?? '';
    final titulo = data['titulo'] ?? '';
    final mensagem = data['mensagem'] ?? '';
    final dataCriacao = data['dataCriacao'] as Timestamp?;
    final icone = _getIconeNotificacao(tipo);
    final corIcone = _getCorNotificacao(tipo);

    return Dismissible(
      key: Key(notificacaoId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _excluirNotificacao(context, notificacaoId);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: lida ? null : theme.colorScheme.surfaceVariant.withOpacity(0.3),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: corIcone.withOpacity(0.2),
            child: Icon(icone, color: corIcone),
          ),
          title: Text(
            titulo,
            style: TextStyle(
              fontWeight: lida ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(mensagem),
              if (dataCriacao != null)
                Text(
                  _formatarData(dataCriacao.toDate()),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
            ],
          ),
          trailing: lida
              ? null
              : Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
          onTap: () => _marcarComoLida(context, notificacaoId, lida),
        ),
      ),
    );
  }

  IconData _getIconeNotificacao(String tipo) {
    switch (tipo) {
      case 'nova_solicitacao':
        return Icons.assignment;
      case 'solicitacao_aprovada':
        return Icons.check_circle;
      case 'solicitacao_rejeitada':
        return Icons.cancel;
      case 'pagamento':
        return Icons.payment;
      case 'avaliacao':
        return Icons.star;
      case 'chat':
        return Icons.chat;
      default:
        return Icons.notifications;
    }
  }

  Color _getCorNotificacao(String tipo) {
    switch (tipo) {
      case 'nova_solicitacao':
        return Colors.blue;
      case 'solicitacao_aprovada':
        return Colors.green;
      case 'solicitacao_rejeitada':
        return Colors.red;
      case 'pagamento':
        return Colors.purple;
      case 'avaliacao':
        return Colors.orange;
      case 'chat':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _formatarData(DateTime data) {
    final agora = DateTime.now();
    final diferenca = agora.difference(data);

    if (diferenca.inDays == 0) {
      if (diferenca.inHours == 0) {
        if (diferenca.inMinutes == 0) {
          return 'Agora';
        }
        return '${diferenca.inMinutes}min atrás';
      }
      return '${diferenca.inHours}h atrás';
    } else if (diferenca.inDays == 1) {
      return 'Ontem';
    } else if (diferenca.inDays < 7) {
      return '${diferenca.inDays} dias atrás';
    } else {
      return DateFormat('dd/MM/yyyy').format(data);
    }
  }

  void _marcarComoLida(BuildContext context, String notificacaoId, bool lida) async {
    if (lida) return; // Já está lida

    try {
      await FirebaseFirestore.instance
          .collection('notificacoes')
          .doc(notificacaoId)
          .update({'lida': true});
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao marcar notificação como lida: $e')),
        );
      }
    }
  }

  void _marcarTodasComoLidas(BuildContext context, String usuarioId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final notificacoes = await FirebaseFirestore.instance
          .collection('notificacoes')
          .where('destinatarioId', isEqualTo: usuarioId)
          .where('lida', isEqualTo: false)
          .get();

      for (final doc in notificacoes.docs) {
        batch.update(doc.reference, {'lida': true});
      }

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todas as notificações foram marcadas como lidas')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao marcar notificações como lidas: $e')),
        );
      }
    }
  }

  void _excluirNotificacao(BuildContext context, String notificacaoId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notificacoes')
          .doc(notificacaoId)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notificação excluída')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir notificação: $e')),
        );
      }
    }
  }

  void _limparNotificacoesAntigas() async {
    // Esta função agora informa sobre a limpeza automática
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Limpeza Automática'),
          content: const Text(
            'As notificações lidas com mais de 7 dias são automaticamente '
            'removidas do servidor diariamente.\n\n'
            'Esta limpeza é feita por uma função do Firebase que roda todos os dias.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendi'),
            ),
          ],
        ),
      );
    }
  }
}
