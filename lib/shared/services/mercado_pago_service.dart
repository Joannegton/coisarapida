import 'package:cloud_functions/cloud_functions.dart';

/// Enum para tipos de transação no Mercado Pago
enum TipoTransacao {
  venda,
  aluguel,
  caucao,
}

/// Serviço unificado para gerenciar pagamentos via Mercado Pago
class MercadoPagoService {
  final FirebaseFunctions _functions;

  MercadoPagoService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  /// Cria uma preferência de pagamento no Mercado Pago
  /// 
  /// Parâmetros:
  /// - [transacaoId]: ID único da transação (vendaId, aluguelId, etc)
  /// - [valor]: Valor a ser cobrado
  /// - [itemNome]: Nome do item/serviço
  /// - [itemDescricao]: Descrição do item/serviço
  /// - [usuarioId]: ID do usuário que está pagando
  /// - [usuarioEmail]: Email do usuário para o Mercado Pago
  /// - [tipo]: Tipo de transação (venda, aluguel, caucao)
  /// 
  /// Este método chama uma Cloud Function do Firebase que
  /// se comunica com a API do Mercado Pago no backend
  /// 
  /// ⚠️ IMPORTANTE PARA TESTES:
  /// 1. Use um Access Token de TEST no Firebase Functions Config
  /// 2. Configure com: firebase functions:config:set mercadopago.access_token="TEST-xxxxx"
  /// 3. Use email de usuário de teste (test_user_xxx@testuser.com)
  /// 4. O retorno incluirá 'sandbox_init_point' para ambiente de testes
  Future<Map<String, dynamic>> criarPreferenciaPagamento({
    required String transacaoId,
    required double valor,
    required String itemNome,
    required String itemDescricao,
    required String usuarioId,
    required String usuarioEmail,
    required TipoTransacao tipo,
  }) async {
    try {
      final callable = _functions.httpsCallable('criarPreferenciaMercadoPago');
      final result = await callable.call({
        'transacaoId': transacaoId,
        'valor': valor,
        'itemNome': itemNome,
        'itemDescricao': itemDescricao,
        'usuarioId': usuarioId,
        'usuarioEmail': usuarioEmail,
        'tipo': tipo.name,
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Erro ao criar preferência de pagamento: $e');
    }
  }

  /// Verifica o status de um pagamento no Mercado Pago
  Future<Map<String, dynamic>> verificarStatusPagamento(
    String paymentId, {
    bool usarSimulacao = false,
  }) async {
    try {
      if (usarSimulacao) {
        await Future.delayed(const Duration(seconds: 1));
        return {
          'status': 'approved',
          'status_detail': 'accredited',
          'transaction_amount': 0.0,
          'payment_id': paymentId,
        };
      }

      final callable = _functions.httpsCallable('verificarPagamentoMercadoPago');
      final result = await callable.call({'paymentId': paymentId});
      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Erro ao verificar status do pagamento: $e');
    }
  }

  /// Processa o retorno do webhook do Mercado Pago
  /// Este método deve ser chamado pela Cloud Function que recebe o webhook
  Future<void> processarWebhook(Map<String, dynamic> webhookData) async {
    try {
      final type = webhookData['type'] as String?;
      final dataId = webhookData['data']?['id'] as String?;

      if (type == 'payment' && dataId != null) {
        // A atualização será feita pela Cloud Function via webhook
        // Este método é mantido para compatibilidade, mas o webhook
        // no backend é responsável por atualizar o status
        await verificarStatusPagamento(dataId);
      }
    } catch (e) {
      throw Exception('Erro ao processar webhook: $e');
    }
  }
}
