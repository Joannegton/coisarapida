import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

/// Resultado do processamento de um deep link de pagamento
class PaymentDeepLinkResult {
  final String status; // success, failure, pending
  final String? paymentId;
  final String? externalReference; // ID do aluguel ou venda
  final String? collectionStatus;

  PaymentDeepLinkResult({
    required this.status,
    this.paymentId,
    this.externalReference,
    this.collectionStatus,
  });

  bool get isSuccess => status == 'success' && collectionStatus == 'approved';
  bool get isFailure => status == 'failure';
  bool get isPending => status == 'pending';
}

/// Serviço unificado para gerenciar Deep Links de retorno do Mercado Pago
/// Segue a documentação oficial: https://www.mercadopago.com.br/developers/pt/docs/checkout-api/integration-configuration/integrate-with-flutter
class PaymentDeepLinkService {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription? _subscription;

  /// Callback chamado quando um deep link de pagamento é recebido
  Function(PaymentDeepLinkResult)? onPaymentResult;

  /// Inicia a escuta de deep links
  void initialize({required Function(PaymentDeepLinkResult) onPaymentResult}) {
    this.onPaymentResult = onPaymentResult;

    // Ouvir link inicial (quando o app é aberto via deep link)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    }).catchError((err) {
      debugPrint('❌ Erro ao obter URI inicial: $err');
    });

    // Ouvir links enquanto o app está aberto
    _subscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('❌ Erro no stream de deep links: $err');
    });
  }

  /// Processa o deep link recebido
  void _handleDeepLink(Uri uri) {
    debugPrint('🔗🔗🔗 ======================================');
    debugPrint('🔗 [PaymentDeepLink] Deep link recebido: $uri');
    debugPrint('📍 Scheme: ${uri.scheme}');
    debugPrint('📍 Host: ${uri.host}');
    debugPrint('📍 Path: ${uri.path}');
    debugPrint('📍 Query params: ${uri.queryParameters}');

    // Validar scheme
    if (uri.scheme != 'coisarapida') {
      debugPrint('❌ [PaymentDeepLink] Scheme inválido: ${uri.scheme}');
      debugPrint('🔗🔗🔗 ======================================');
      return;
    }

    // O Mercado Pago envia: coisarapida://success?params
    // O host será 'success', 'failure' ou 'pending'
    final status = uri.host;

    // Validar status
    if (status.isEmpty ||
        (status != 'success' && status != 'failure' && status != 'pending')) {
      debugPrint('❌ [PaymentDeepLink] Status inválido: $status');
      debugPrint('🔗🔗🔗 ======================================');
      return;
    }

    // Extrair parâmetros retornados pelo Mercado Pago
    var externalReference = uri.queryParameters['external_reference'];

    final result = PaymentDeepLinkResult(
      status: status,
      paymentId: uri.queryParameters['payment_id'],
      externalReference: externalReference,
      collectionStatus: uri.queryParameters['collection_status'],
    );

    // Notificar callback
    if (onPaymentResult != null) {
      debugPrint('🚀 [PaymentDeepLink] Chamando callback...');
      onPaymentResult?.call(result);
      debugPrint('✅ [PaymentDeepLink] Callback executado');
    } else {
      debugPrint('⚠️ [PaymentDeepLink] Nenhum callback definido!');
    }

    debugPrint('🔗🔗🔗 ======================================');
  }

  /// Cancela a escuta de deep links
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    onPaymentResult = null;
  }
}
