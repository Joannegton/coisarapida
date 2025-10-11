import 'package:cloud_functions/cloud_functions.dart';

/// Serviço para gerenciar pagamentos via Mercado Pago
class MercadoPagoService {
  final FirebaseFunctions _functions;

  MercadoPagoService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  /// Cria uma preferência de pagamento no Mercado Pago
  /// 
  /// Este método chama uma Cloud Function do Firebase que
  /// se comunica com a API do Mercado Pago no backend
  Future<Map<String, dynamic>> criarPreferenciaPagamento({
    required String aluguelId,
    required double valor,
    required String itemNome,
    required String itemDescricao,
    required String locatarioId,
    required String locatarioEmail,
  }) async {
    try {
      final callable = _functions.httpsCallable('criarPreferenciaMercadoPago');
      final result = await callable.call({
        'aluguelId': aluguelId,
        'valor': valor,
        'itemNome': itemNome,
        'itemDescricao': itemDescricao,
        'locatarioId': locatarioId,
        'locatarioEmail': locatarioEmail,
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
