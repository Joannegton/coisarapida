import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Enumeração dos tipos de notificação
enum TipoNotificacao {
  novaSolicitacao('nova_solicitacao', 'Nova solicitação de aluguel'),
  solicitacaoAprovada('solicitacao_aprovada', 'Solicitação aprovada'),
  solicitacaoRecusada('solicitacao_recusada', 'Solicitação recusada'),
  pagamentoPendente('pagamento_pendente', 'Pagamento pendente'),
  pagamentoConfirmado('pagamento_confirmado', 'Pagamento confirmado'),
  aluguelIniciado('aluguel_iniciado', 'Aluguel iniciado'),
  lembreteDevolucao('lembrete_devolucao', 'Lembrete de devolução'),
  devolucaoSolicitada('devolucao_solicitada', 'Devolução solicitada'),
  devolucaoAprovada('devolucao_aprovada', 'Devolução aprovada'),
  avaliacaoPendente('avaliacao_pendente', 'Avaliação pendente'),
  mensagemChat('mensagem_chat', 'Nova mensagem'),
  aprovacaoResidencia('aprovacao_residencia', 'Verificação de residência aprovada'),
  rejeicaoResidencia('rejeicao_residencia', 'Verificação de residência rejeitada'),
  aprovacaoConta('aprovacao_conta', 'Conta aprovada');

  final String value;
  final String label;
  const TipoNotificacao(this.value, this.label);
}

/// Gerenciador de notificações do sistema
class NotificationManager {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  NotificationManager({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  /// Envia notificação quando uma nova solicitação é criada
  Future<void> notificarNovaSolicitacao({
    required String locadorId,
    required String locatarioNome,
    required String itemNome,
    required String aluguelId,
  }) async {
    try {
      await _enviarNotificacao(
        destinatarioId: locadorId,
        tipo: TipoNotificacao.novaSolicitacao,
        titulo: 'Nova Solicitação de Aluguel',
        mensagem: '$locatarioNome solicitou alugar seu item "$itemNome"',
        dados: {
          'aluguelId': aluguelId,
          'tipo': TipoNotificacao.novaSolicitacao.value,
          'rota': '/status-aluguel/$aluguelId',
        },
      );
    } catch (e) {
      debugPrint('❌ Erro ao enviar notificação de nova solicitação: $e');
    }
  }

  /// Envia notificação quando uma solicitação é aprovada
  Future<void> notificarSolicitacaoAprovada({
    required String locatarioId,
    required String locadorNome,
    required String itemNome,
    required String aluguelId,
  }) async {
    try {
      await _enviarNotificacao(
        destinatarioId: locatarioId,
        tipo: TipoNotificacao.solicitacaoAprovada,
        titulo: 'Solicitação Aprovada! 🎉',
        mensagem: '$locadorNome aprovou sua solicitação para "$itemNome"',
        dados: {
          'aluguelId': aluguelId,
          'tipo': TipoNotificacao.solicitacaoAprovada.value,
          'rota': '/status-aluguel/$aluguelId',
        },
      );
      debugPrint('✅ Notificação de solicitação aprovada enviada para $locatarioId');
    } catch (e) {
      debugPrint('❌ Erro ao enviar notificação de solicitação aprovada: $e');
    }
  }

  /// Envia notificação quando uma solicitação é recusada
  Future<void> notificarSolicitacaoRecusada({
    required String locatarioId,
    required String locadorNome,
    required String itemNome,
    required String aluguelId,
    String? motivo,
  }) async {
    try {
      final mensagem = motivo != null
          ? '$locadorNome recusou sua solicitação para "$itemNome". Motivo: $motivo'
          : '$locadorNome recusou sua solicitação para "$itemNome"';

      await _enviarNotificacao(
        destinatarioId: locatarioId,
        tipo: TipoNotificacao.solicitacaoRecusada,
        titulo: 'Solicitação Recusada',
        mensagem: mensagem,
        dados: {
          'aluguelId': aluguelId,
          'tipo': TipoNotificacao.solicitacaoRecusada.value,
          'rota': '/status-aluguel/$aluguelId',
        },
      );
      debugPrint('✅ Notificação de solicitação recusada enviada para $locatarioId');
    } catch (e) {
      debugPrint('❌ Erro ao enviar notificação de solicitação recusada: $e');
    }
  }

  /// Envia notificação quando um pagamento está pendente
  Future<void> notificarPagamentoPendente({
    required String locatarioId,
    required String itemNome,
    required String aluguelId,
    required double valor,
  }) async {
    try {
      await _enviarNotificacao(
        destinatarioId: locatarioId,
        tipo: TipoNotificacao.pagamentoPendente,
        titulo: 'Pagamento Pendente',
        mensagem: 'Complete o pagamento de R\$ ${valor.toStringAsFixed(2)} para "$itemNome"',
        dados: {
          'aluguelId': aluguelId,
          'tipo': TipoNotificacao.pagamentoPendente.value,
          'rota': '/status-aluguel/$aluguelId',
        },
      );
      debugPrint('✅ Notificação de pagamento pendente enviada para $locatarioId');
    } catch (e) {
      debugPrint('❌ Erro ao enviar notificação de pagamento pendente: $e');
    }
  }

  /// Envia notificação quando o pagamento é confirmado
  Future<void> notificarPagamentoConfirmado({
    required String locadorId,
    required String locatarioId,
    required String itemNome,
    required String aluguelId,
  }) async {
    try {
      // Notificar o locador
      await _enviarNotificacao(
        destinatarioId: locadorId,
        tipo: TipoNotificacao.pagamentoConfirmado,
        titulo: 'Pagamento Confirmado! 💰',
        mensagem: 'Pagamento recebido para o aluguel de "$itemNome"',
        dados: {
          'aluguelId': aluguelId,
          'tipo': TipoNotificacao.pagamentoConfirmado.value,
          'rota': '/status-aluguel/$aluguelId',
        },
      );

      // Notificar o locatário
      await _enviarNotificacao(
        destinatarioId: locatarioId,
        tipo: TipoNotificacao.pagamentoConfirmado,
        titulo: 'Pagamento Confirmado! ✅',
        mensagem: 'Seu pagamento para "$itemNome" foi confirmado',
        dados: {
          'aluguelId': aluguelId,
          'tipo': TipoNotificacao.pagamentoConfirmado.value,
          'rota': '/status-aluguel/$aluguelId',
        },
      );
      debugPrint('✅ Notificações de pagamento confirmado enviadas');
    } catch (e) {
      debugPrint('❌ Erro ao enviar notificação de pagamento confirmado: $e');
    }
  }

  /// Envia notificação de lembrete de devolução
  Future<void> notificarLembreteDevolucao({
    required String locatarioId,
    required String itemNome,
    required String aluguelId,
    required DateTime dataFim,
  }) async {
    try {
      final diasRestantes = dataFim.difference(DateTime.now()).inDays;
      final mensagem = diasRestantes == 0
          ? 'O prazo de devolução de "$itemNome" termina hoje!'
          : 'Faltam $diasRestantes dias para devolver "$itemNome"';

      await _enviarNotificacao(
        destinatarioId: locatarioId,
        tipo: TipoNotificacao.lembreteDevolucao,
        titulo: 'Lembrete de Devolução',
        mensagem: mensagem,
        dados: {
          'aluguelId': aluguelId,
          'tipo': TipoNotificacao.lembreteDevolucao.value,
          'rota': '/status-aluguel/$aluguelId',
        },
      );
      debugPrint('✅ Notificação de lembrete de devolução enviada para $locatarioId');
    } catch (e) {
      debugPrint('❌ Erro ao enviar notificação de lembrete de devolução: $e');
    }
  }

  /// Envia notificação quando a devolução é solicitada
  Future<void> notificarDevolucaoSolicitada({
    required String locadorId,
    required String locatarioNome,
    required String itemNome,
    required String aluguelId,
  }) async {
    try {
      await _enviarNotificacao(
        destinatarioId: locadorId,
        tipo: TipoNotificacao.devolucaoSolicitada,
        titulo: 'Devolução Solicitada',
        mensagem: '$locatarioNome solicitou a devolução de "$itemNome"',
        dados: {
          'aluguelId': aluguelId,
          'tipo': TipoNotificacao.devolucaoSolicitada.value,
          'rota': '/status-aluguel/$aluguelId',
        },
      );
      debugPrint('✅ Notificação de devolução solicitada enviada para $locadorId');
    } catch (e) {
      debugPrint('❌ Erro ao enviar notificação de devolução solicitada: $e');
    }
  }

  /// Envia notificação quando a devolução é aprovada
  Future<void> notificarDevolucaoAprovada({
    required String locatarioId,
    required String itemNome,
    required String aluguelId,
  }) async {
    try {
      await _enviarNotificacao(
        destinatarioId: locatarioId,
        tipo: TipoNotificacao.devolucaoAprovada,
        titulo: 'Devolução Aprovada! ✅',
        mensagem: 'A devolução de "$itemNome" foi aprovada',
        dados: {
          'aluguelId': aluguelId,
          'tipo': TipoNotificacao.devolucaoAprovada.value,
          'rota': '/status-aluguel/$aluguelId',
        },
      );
      debugPrint('✅ Notificação de devolução aprovada enviada para $locatarioId');
    } catch (e) {
      debugPrint('❌ Erro ao enviar notificação de devolução aprovada: $e');
    }
  }

  /// Envia notificação de avaliação pendente
  Future<void> notificarAvaliacaoPendente({
    required String usuarioId,
    required String avaliadoNome,
    required String itemNome,
    required String aluguelId,
  }) async {
    try {
      await _enviarNotificacao(
        destinatarioId: usuarioId,
        tipo: TipoNotificacao.avaliacaoPendente,
        titulo: 'Avaliação Pendente ⭐',
        mensagem: 'Avalie sua experiência com $avaliadoNome e "$itemNome"',
        dados: {
          'aluguelId': aluguelId,
          'tipo': TipoNotificacao.avaliacaoPendente.value,
          'rota': '/avaliacoes-pendentes',
        },
      );
      debugPrint('✅ Notificação de avaliação pendente enviada para $usuarioId');
    } catch (e) {
      debugPrint('❌ Erro ao enviar notificação de avaliação pendente: $e');
    }
  }

  /// Método privado para enviar notificação
  Future<void> _enviarNotificacao({
    required String destinatarioId,
    required TipoNotificacao tipo,
    required String titulo,
    required String mensagem,
    required Map<String, dynamic> dados,
  }) async {
    try {
      // 1. Sempre salvar notificação no Firestore (para histórico)
      await _salvarNotificacaoFirestore(
        destinatarioId: destinatarioId,
        tipo: tipo,
        titulo: titulo,
        mensagem: mensagem,
        dados: dados,
      );

      // 2. Buscar o FCM token do destinatário
      final userDoc = await _firestore.collection('usuarios').doc(destinatarioId).get();

      if (!userDoc.exists) {
        debugPrint('⚠️ Usuário $destinatarioId não encontrado');
        return;
      }

      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null) {
        debugPrint('⚠️ FCM Token não encontrado para usuário $destinatarioId');
        return;
      }

      // 3. Tentar enviar push notification via Cloud Function
      try {
        final result = await _functions.httpsCallable('enviarNotificacao').call({
          'token': fcmToken,
          'titulo': titulo,
          'mensagem': mensagem,
          'dados': dados,
        });

        debugPrint('✅ Notificação push enviada com sucesso: ${result.data}');
      } catch (e) {
        debugPrint('⚠️ Falha ao enviar push notification, mas notificação salva no Firestore: $e');
        // Não é erro crítico pois a notificação já foi salva no Firestore
      }
    } catch (e) {
      debugPrint('❌ Erro ao processar notificação: $e');
      rethrow;
    }
  }

  /// Salva a notificação no Firestore (sempre, para manter histórico)
  Future<void> _salvarNotificacaoFirestore({
    required String destinatarioId,
    required TipoNotificacao tipo,
    required String titulo,
    required String mensagem,
    required Map<String, dynamic> dados,
  }) async {
    try {
      await _firestore.collection('notificacoes').add({
        'destinatarioId': destinatarioId,
        'tipo': tipo.value,
        'titulo': titulo,
        'mensagem': mensagem,
        'dados': dados,
        'lida': false,
        'dataCriacao': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Notificação salva no Firestore para histórico');
    } catch (e) {
      debugPrint('❌ Erro ao salvar notificação no Firestore: $e');
    }
  }
}
