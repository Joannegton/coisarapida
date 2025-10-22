const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Inicializar Firebase Admin
admin.initializeApp();

// Importar e exportar funções do Mercado Pago
const mercadoPagoFunctions = require('./mercado_pago');

exports.criarPreferenciaMercadoPago = mercadoPagoFunctions.criarPreferenciaMercadoPago;
exports.webhookMercadoPago = mercadoPagoFunctions.webhookMercadoPago;
exports.verificarPagamentoMercadoPago = mercadoPagoFunctions.verificarPagamentoMercadoPago;

// Importar e exportar funções de notificações
const notificationFunctions = require('./notifications');

exports.enviarNotificacao = notificationFunctions.enviarNotificacao;
exports.enviarNotificacaoMultipla = notificationFunctions.enviarNotificacaoMultipla;
exports.notificarNovaSolicitacao = notificationFunctions.notificarNovaSolicitacao;
exports.notificarAtualizacaoSolicitacao = notificationFunctions.notificarAtualizacaoSolicitacao;

// Importar e exportar funções de avaliações
const avaliacoesFunctions = require('./avaliacoes');

exports.calcularReputacaoUsuario = avaliacoesFunctions.calcularReputacaoUsuario;
exports.recalcularTodasReputacoes = avaliacoesFunctions.recalcularTodasReputacoes;
exports.obterEstatisticasAvaliacoes = avaliacoesFunctions.obterEstatisticasAvaliacoes;

// Função para limpar notificações antigas (chamada via HTTP)
exports.limparNotificacoesAntigas = functions.https.onRequest(async (req, res) => {
  // Verificar se é uma requisição POST (para segurança)
  if (req.method !== 'POST') {
    res.status(405).send('Método não permitido');
    return;
  }

  const db = admin.firestore();

  try {
    console.log('🧹 Iniciando limpeza de notificações antigas...');

    // Data limite: 7 dias atrás
    const dataLimite = new Date();
    dataLimite.setDate(dataLimite.getDate() - 7);

    // Buscar TODAS as notificações lidas primeiro, depois filtrar por data no código
    // Isso evita a necessidade de índice composto
    const notificacoesLidas = await db
      .collection('notificacoes')
      .where('lida', '==', true)
      .get();

    const notificacoesAntigas = [];
    notificacoesLidas.docs.forEach((doc) => {
      const data = doc.data();
      if (data.dataCriacao && data.dataCriacao.toDate() < dataLimite) {
        notificacoesAntigas.push(doc);
      }
    });

    if (notificacoesAntigas.length === 0) {
      console.log('ℹ️ Nenhuma notificação antiga para limpar');
      res.status(200).json({
        success: true,
        message: 'Nenhuma notificação antiga para limpar',
        removidas: 0
      });
      return;
    }

    // Excluir notificações antigas em lote
    const batch = db.batch();
    notificacoesAntigas.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();

    const quantidadeRemovida = notificacoesAntigas.length;
    console.log(`🗑️ ${quantidadeRemovida} notificações antigas removidas com sucesso`);

    res.status(200).json({
      success: true,
      message: `${quantidadeRemovida} notificações antigas removidas`,
      removidas: quantidadeRemovida
    });
  } catch (error) {
    console.error('❌ Erro ao limpar notificações antigas:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao limpar notificações antigas',
      error: error.message
    });
  }
});
