const admin = require('firebase-admin');

// Inicializar Firebase Admin
admin.initializeApp();

// Importar e exportar funções do Mercado Pago
const mercadoPagoFunctions = require('./mercado_pago');

exports.criarPreferenciaMercadoPago = mercadoPagoFunctions.criarPreferenciaMercadoPago;
exports.webhookMercadoPago = mercadoPagoFunctions.webhookMercadoPago;
exports.verificarPagamentoMercadoPago = mercadoPagoFunctions.verificarPagamentoMercadoPago;
