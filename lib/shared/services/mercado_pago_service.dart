import 'package:coisarapida/core/services/api_client.dart';
import 'package:flutter/foundation.dart';

/// Enum para tipos de transação no Mercado Pago
enum TipoTransacao {
  venda,
  aluguel,
  caucao,
}

/// Serviço unificado para gerenciar pagamentos via Mercado Pago
class MercadoPagoService {
  final ApiClient _apiClient;

  MercadoPagoService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Cria uma preferência de pagamento e retorna dados do checkout
  /// Retorna uma Map com 'init_point' (URL de checkout) e 'preferenceId'
  Future<Map<String, dynamic>> criarPreferenciaPagamento({
    required String aluguelId,
    required double valor,
    required String itemNome,
    required String itemDescricao,
    required String locatarioId,
    required String locadorId,
    required String locatarioEmail,
    required TipoTransacao tipo,
    required String locatarioNome,
    String? locatarioTelefone,
  }) async {
    try {
      final body = {
        'aluguelId': aluguelId,
        'valor': valor,
        'itemNome': itemNome,
        'itemDescricao': itemDescricao,
        'locatarioEmail': locatarioEmail,
        'locatarioNome': locatarioNome,
        'locatarioTelefone': locatarioTelefone,
        'locatarioId': locatarioId,
        'locadorId': locadorId,
        'tipo': tipo.name,
      };

      debugPrint('Resposta do criarPreferenciaPagamento: $body');
      final response =
          await _apiClient.post('/checkout/mercado-pago/criar', body: body);

      if (response.isNotEmpty && response['data'] != null) {
        return {
          'init_point': response['data']['init_point'] as String,
          'preferenceId': response['data']['id'] as String?,
          'aluguelId': response['data']['aluguelId'] as String?,
        };
      } else {
        throw Exception('Erro ao criar checkout');
      }
    } catch (e) {
      throw Exception('Erro ao criar preferência de pagamento: $e');
    }
  }

  /// Verifica o status de um pagamento no Mercado Pago pelo paymentId
  /// Esta é uma consulta de fallback caso o deep link falhe
  Future<Map<String, dynamic>> verificarStatusPagamento(
    String paymentId, {
    bool usarSimulacao = false,
  }) async {
    try {
      final response = await this._apiClient.post(
        '/checkout/mercado-pago/status',
        body: {
          'paymentId': paymentId,
        },
      );

      if (response.isNotEmpty && response['data'] != null) {
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception('Erro ao verificar status');
      }
    } catch (e) {
      throw Exception('Erro ao verificar status do pagamento: $e');
    }
  }
}
