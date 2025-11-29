import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coisarapida/shared/services/payment_deep_link_service.dart';

/// Este provider garante que apenas uma instância do serviço é criada
final paymentDeepLinkServiceProvider = Provider<PaymentDeepLinkService>((ref) {
  return PaymentDeepLinkService();
});
