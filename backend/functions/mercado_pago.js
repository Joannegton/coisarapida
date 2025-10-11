const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
const axios = require('axios');

// Inicializar Firebase Admin (faça isso apenas uma vez)
// admin.initializeApp();

/**
 * Cloud Function para criar preferência de pagamento no Mercado Pago
 */
exports.criarPreferenciaMercadoPago = functions.https.onCall(async (data, context) => {
  // Verificar autenticação
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Usuário não autenticado');
  }

  const { aluguelId, valor, itemNome, itemDescricao, locatarioEmail } = data;

  // Validar dados
  if (!aluguelId || !valor || !itemNome) {
    throw new functions.https.HttpsError('invalid-argument', 'Dados incompletos');
  }

  // Obter Access Token das variáveis de ambiente
  // Configure com: firebase functions:config:set mercadopago.access_token="SEU_TOKEN"
  const accessToken = functions.config().mercadopago?.access_token;
  
  if (!accessToken) {
    throw new functions.https.HttpsError('failed-precondition', 'Mercado Pago não configurado');
  }

  try {
    // Criar preferência no Mercado Pago
    const preference = {
      items: [
        {
          title: itemNome,
          description: itemDescricao || 'Caução de aluguel',
          quantity: 1,
          currency_id: 'BRL',
          unit_price: parseFloat(valor),
        }
      ],
      payer: {
        email: locatarioEmail,
      },
      back_urls: {
        success: 'coisarapida://payment/success',
        failure: 'coisarapida://payment/failure',
        pending: 'coisarapida://payment/pending',
      },
      auto_return: 'approved',
      external_reference: aluguelId, // Referência para identificar o aluguel
      statement_descriptor: 'COISARAPIDA', // Aparece na fatura do cartão
      notification_url: `https://${process.env.GCLOUD_PROJECT}.cloudfunctions.net/webhookMercadoPago`,
      expires: true,
      expiration_date_from: new Date().toISOString(),
      expiration_date_to: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(), // 24 horas
      // Configurações para evitar abertura do app nativo do Mercado Pago
      binary_mode: false,
      marketplace: 'NONE',
      marketplace_fee: 0,
    };

    const response = await axios.post(
      'https://api.mercadopago.com/checkout/preferences',
      preference,
      {
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        }
      }
    );

    console.log(`Preferência criada: ${response.data.id} para aluguel ${aluguelId}`);

    return {
      id: response.data.id,
      init_point: response.data.init_point,
      sandbox_init_point: response.data.sandbox_init_point,
    };

  } catch (error) {
    console.error('Erro ao criar preferência:', error.response?.data || error.message);
    
    if (error.response?.status === 401) {
      throw new functions.https.HttpsError('unauthenticated', 'Credenciais do Mercado Pago inválidas');
    }
    
    throw new functions.https.HttpsError('internal', 'Erro ao criar preferência de pagamento');
  }
});

/**
 * Webhook para receber notificações do Mercado Pago
 */
exports.webhookMercadoPago = functions.https.onRequest(async (req, res) => {
  // Apenas aceitar POST
  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }

  console.log('Webhook recebido:', JSON.stringify(req.body));

  const { type, data, action } = req.body;

  // Mercado Pago envia notificações de diferentes tipos
  if (type === 'payment' && data?.id) {
    const paymentId = data.id;
    const accessToken = functions.config().mercadopago?.access_token;

    if (!accessToken) {
      console.error('Access token não configurado');
      res.status(500).send('Internal Server Error');
      return;
    }

    try {
      // Buscar detalhes do pagamento
      const response = await axios.get(
        `https://api.mercadopago.com/v1/payments/${paymentId}`,
        {
          headers: {
            'Authorization': `Bearer ${accessToken}`,
          }
        }
      );

      const payment = response.data;
      const aluguelId = payment.external_reference;
      const status = payment.status;

      console.log(`Pagamento ${paymentId} - Status: ${status} - Aluguel: ${aluguelId}`);

      if (!aluguelId) {
        console.warn('Pagamento sem external_reference');
        res.status(200).send('OK');
        return;
      }

      // Atualizar status no Firestore
      const aluguelRef = admin.firestore().collection('alugueis').doc(aluguelId);
      const aluguelDoc = await aluguelRef.get();

      if (!aluguelDoc.exists) {
        console.warn(`Aluguel ${aluguelId} não encontrado`);
        res.status(200).send('OK');
        return;
      }

      // Mapear status do Mercado Pago para status da caução
      let caucaoStatus = 'pendente';
      if (status === 'approved') {
        caucaoStatus = 'bloqueada';
      } else if (status === 'rejected' || status === 'cancelled') {
        caucaoStatus = 'falhou';
      }

      await aluguelRef.update({
        'caucao.status': caucaoStatus,
        'caucao.transacaoId': paymentId,
        'caucao.dataBloqueio': admin.firestore.FieldValue.serverTimestamp(),
        'caucao.statusMercadoPago': status,
        'caucao.statusDetail': payment.status_detail,
        'atualizadoEm': admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Aluguel ${aluguelId} atualizado com sucesso`);

      res.status(200).send('OK');
    } catch (error) {
      console.error('Erro ao processar webhook:', error.response?.data || error.message);
      res.status(500).send('Internal Server Error');
    }
  } else {
    // Outros tipos de notificação (merchant_order, etc.)
    console.log(`Notificação ignorada - Tipo: ${type}`);
    res.status(200).send('OK');
  }
});

/**
 * Cloud Function para verificar status de um pagamento
 */
exports.verificarPagamentoMercadoPago = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Usuário não autenticado');
  }

  const { paymentId } = data;

  if (!paymentId) {
    throw new functions.https.HttpsError('invalid-argument', 'Payment ID não fornecido');
  }

  const accessToken = functions.config().mercadopago?.access_token;

  if (!accessToken) {
    throw new functions.https.HttpsError('failed-precondition', 'Mercado Pago não configurado');
  }

  try {
    const response = await axios.get(
      `https://api.mercadopago.com/v1/payments/${paymentId}`,
      {
        headers: {
          'Authorization': `Bearer ${accessToken}`,
        }
      }
    );

    return {
      status: response.data.status,
      status_detail: response.data.status_detail,
      transaction_amount: response.data.transaction_amount,
      payment_id: response.data.id,
      external_reference: response.data.external_reference,
    };

  } catch (error) {
    console.error('Erro ao verificar pagamento:', error.response?.data || error.message);
    throw new functions.https.HttpsError('internal', 'Erro ao verificar pagamento');
  }
});
