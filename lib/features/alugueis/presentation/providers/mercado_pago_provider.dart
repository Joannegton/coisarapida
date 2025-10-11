import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/mercado_pago_service.dart';

/// Provider para o serviço do Mercado Pago
final mercadoPagoServiceProvider = Provider<MercadoPagoService>((ref) {
  return MercadoPagoService();
});
