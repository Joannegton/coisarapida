const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { v4: uuidv4 } = require('uuid');

// Configuração para Cloud Vision (análise de imagem)
// const vision = require('@google-cloud/vision');
// const client = new vision.ImageAnnotatorClient();

/**
 * Solicita verificação de residência enviando comprovante
 */
exports.solicitarVerificacaoResidencia = functions.https.onCall(async (data, context) => {
  // Verificar autenticação
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Usuário não autenticado');
  }

  const { comprovanteUrl, endereco } = data;
  const userId = context.auth.uid;

  // Validar dados
  if (!comprovanteUrl || !endereco) {
    throw new functions.https.HttpsError('invalid-argument', 'Dados incompletos');
  }

  try {
    const db = admin.firestore();
    
    // Verificar se já existe verificação pendente
    const verificacoesPendentes = await db
      .collection('verificacoes_residencia')
      .where('userId', '==', userId)
      .where('status', '==', 'pendente')
      .get();

    if (!verificacoesPendentes.empty) {
      throw new functions.https.HttpsError('already-exists', 'Já existe uma verificação pendente');
    }

    // Análise automática básica (sem Cloud Vision para começar)
    const analiseAutomatica = {
      comprovanteEnviado: true,
      dataEnvio: new Date().toISOString(),
      enderecoDeclarado: endereco,
    };

    // Opcional: Análise com Cloud Vision
    /*
    try {
      const [result] = await client.textDetection(comprovanteUrl);
      const textoExtraido = result.fullTextAnnotation?.text || '';
      
      analiseAutomatica.textoExtraido = textoExtraido;
      analiseAutomatica.contemCEP = /\d{5}-?\d{3}/.test(textoExtraido);
      analiseAutomatica.contemCidade = textoExtraido.toLowerCase().includes(endereco.cidade.toLowerCase());
      analiseAutomatica.contemRua = textoExtraido.toLowerCase().includes(endereco.rua.toLowerCase().split(' ')[0]);
    } catch (visionError) {
      console.error('Erro na análise Vision:', visionError);
      analiseAutomatica.erroAnalise = visionError.message;
    }
    */

    // Salvar verificação no Firestore
    const verificacaoRef = await db.collection('verificacoes_residencia').add({
      userId,
      comprovanteUrl,
      enderecoDeclarado: endereco,
      analiseAutomatica,
      status: 'pendente',
      criadoEm: admin.firestore.FieldValue.serverTimestamp(),
      atualizadoEm: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Notificar admins sobre nova verificação pendente
    await notificarAdminNovaVerificacao(verificacaoRef.id, userId);

    return {
      success: true,
      verificacaoId: verificacaoRef.id,
      message: 'Comprovante enviado para análise. Você será notificado em até 48h.',
      analiseAutomatica,
    };
  } catch (error) {
    console.error('Erro ao solicitar verificação:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Aprovar ou rejeitar verificação de residência (apenas admin)
 */
exports.processarVerificacaoResidencia = functions.https.onCall(async (data, context) => {
  // Verificar autenticação
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Usuário não autenticado');
  }

  const { verificacaoId, aprovado, motivo } = data;

  try {
    const db = admin.firestore();
    
    // Buscar verificação
    const verificacaoDoc = await db
      .collection('verificacoes_residencia')
      .doc(verificacaoId)
      .get();

    if (!verificacaoDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Verificação não encontrada');
    }

    const verificacao = verificacaoDoc.data();

    // Verificar se o usuário é admin ou o próprio usuário
    const userDoc = await db.collection('usuarios').doc(context.auth.uid).get();
    const isAdmin = userDoc.data()?.admin === true;

    if (!isAdmin && context.auth.uid !== verificacao.userId) {
      throw new functions.https.HttpsError('permission-denied', 'Sem permissão para processar esta verificação');
    }

    // Atualizar status da verificação
    await db.collection('verificacoes_residencia').doc(verificacaoId).update({
      status: aprovado ? 'aprovado' : 'rejeitado',
      motivo: motivo || null,
      processadoEm: admin.firestore.FieldValue.serverTimestamp(),
      processadoPor: context.auth.uid,
      atualizadoEm: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Atualizar status de verificação no perfil do usuário
    await db.collection('usuarios').doc(verificacao.userId).update({
      enderecoVerificado: aprovado,
      verificacaoResidenciaData: admin.firestore.FieldValue.serverTimestamp(),
      motivoRejeicaoResidencia: motivo || null,
    });

    // Notificar usuário sobre resultado
    await notificarUsuarioResultadoVerificacao(verificacao.userId, aprovado, motivo);

    return {
      success: true,
      message: aprovado ? 'Verificação aprovada com sucesso' : 'Verificação rejeitada',
    };
  } catch (error) {
    console.error('Erro ao processar verificação:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Listar verificações pendentes (apenas admin)
 */
exports.listarVerificacoesPendentes = functions.https.onCall(async (data, context) => {
  // Verificar autenticação
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Usuário não autenticado');
  }

  try {
    const db = admin.firestore();
    
    // Verificar se é admin
    const userDoc = await db.collection('usuarios').doc(context.auth.uid).get();
    const isAdmin = userDoc.data()?.admin === true;

    if (!isAdmin) {
      throw new functions.https.HttpsError('permission-denied', 'Apenas admins podem listar verificações');
    }

    // Buscar verificações pendentes
    const verificacoesSnapshot = await db
      .collection('verificacoes_residencia')
      .where('status', '==', 'pendente')
      .orderBy('criadoEm', 'desc')
      .limit(50)
      .get();

    const verificacoes = [];
    for (const doc of verificacoesSnapshot.docs) {
      const verificacao = doc.data();
      
      // Buscar dados do usuário
      const usuarioDoc = await db.collection('usuarios').doc(verificacao.userId).get();
      const usuario = usuarioDoc.data();

      verificacoes.push({
        id: doc.id,
        ...verificacao,
        usuario: {
          id: verificacao.userId,
          nome: usuario?.nome || 'Desconhecido',
          email: usuario?.email || '',
          telefone: usuario?.telefone || '',
        },
      });
    }

    return {
      success: true,
      verificacoes,
    };
  } catch (error) {
    console.error('Erro ao listar verificações:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Funções auxiliares
 */

async function notificarAdminNovaVerificacao(verificacaoId, userId) {
  try {
    const db = admin.firestore();
    
    // Buscar todos os admins
    const adminsSnapshot = await db
      .collection('usuarios')
      .where('admin', '==', true)
      .get();

    // Buscar dados do usuário
    const usuarioDoc = await db.collection('usuarios').doc(userId).get();
    const usuario = usuarioDoc.data();

    // Enviar notificação para cada admin
    const notificacoes = adminsSnapshot.docs.map(async (adminDoc) => {
      return db.collection('notificacoes').add({
        usuarioId: adminDoc.id,
        tipo: 'verificacao_pendente',
        titulo: 'Nova verificação de residência',
        mensagem: `${usuario?.nome || 'Usuário'} enviou comprovante de residência para análise`,
        lida: false,
        dataCriacao: admin.firestore.FieldValue.serverTimestamp(),
        dados: {
          verificacaoId,
          userId,
        },
      });
    });

    await Promise.all(notificacoes);
  } catch (error) {
    console.error('Erro ao notificar admin:', error);
  }
}

async function notificarUsuarioResultadoVerificacao(userId, aprovado, motivo) {
  try {
    const db = admin.firestore();
    
    await db.collection('notificacoes').add({
      usuarioId: userId,
      tipo: 'verificacao_resultado',
      titulo: aprovado ? 'Verificação aprovada! ✅' : 'Verificação rejeitada',
      mensagem: aprovado
        ? 'Seu comprovante de residência foi verificado com sucesso!'
        : `Sua verificação foi rejeitada. Motivo: ${motivo || 'Não especificado'}`,
      lida: false,
      dataCriacao: admin.firestore.FieldValue.serverTimestamp(),
      dados: {
        aprovado,
        motivo,
      },
    });
  } catch (error) {
    console.error('Erro ao notificar usuário:', error);
  }
}
