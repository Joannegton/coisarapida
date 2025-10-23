import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mercado_pago_service.dart';

/// Provider para o serviço unificado de Mercado Pago
/// Compartilhado entre vendas, aluguéis e caução
final mercadoPagoServiceProvider = Provider<MercadoPagoService>((ref) {
  return MercadoPagoService();
});
