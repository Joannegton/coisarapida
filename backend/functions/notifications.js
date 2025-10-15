const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');

/**
 * Cloud Function para enviar notificações push via FCM
 */
exports.enviarNotificacao = functions.https.onCall(async (data, context) => {
  // Verificar autenticação
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Usuário não autenticado');
  }

  const { token, titulo, mensagem, dados } = data;

  // Validar dados
  if (!token || !titulo || !mensagem) {
    throw new functions.https.HttpsError('invalid-argument', 'Dados incompletos: token, titulo e mensagem são obrigatórios');
  }

  try {
    // Montar a mensagem
    const message = {
      token: token,
      notification: {
        title: titulo,
        body: mensagem,
      },
      data: dados || {},
      android: {
        priority: 'high',
        notification: {
          channelId: 'aluguel_notifications',
          sound: 'default',
          priority: 'high',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    // Enviar notificação
    const response = await admin.messaging().send(message);
    
    console.log('✅ Notificação enviada com sucesso:', response);
    
    return { 
      success: true, 
      messageId: response,
      message: 'Notificação enviada com sucesso' 
    };
  } catch (error) {
    console.error('❌ Erro ao enviar notificação:', error);
    
    // Se o token for inválido, remover do usuário
    if (error.code === 'messaging/invalid-registration-token' || 
        error.code === 'messaging/registration-token-not-registered') {
      console.log('🗑️ Token inválido, removendo do usuário');
      // Aqui você poderia remover o token do Firestore se necessário
    }
    
    throw new functions.https.HttpsError('internal', `Erro ao enviar notificação: ${error.message}`);
  }
});

/**
 * Cloud Function para enviar notificação para múltiplos dispositivos
 */
exports.enviarNotificacaoMultipla = functions.https.onCall(async (data, context) => {
  // Verificar autenticação
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Usuário não autenticado');
  }

  const { tokens, titulo, mensagem, dados } = data;

  // Validar dados
  if (!tokens || !Array.isArray(tokens) || tokens.length === 0 || !titulo || !mensagem) {
    throw new functions.https.HttpsError('invalid-argument', 'Dados incompletos ou inválidos');
  }

  try {
    // Montar a mensagem multicast
    const message = {
      tokens: tokens,
      notification: {
        title: titulo,
        body: mensagem,
      },
      data: dados || {},
      android: {
        priority: 'high',
        notification: {
          channelId: 'aluguel_notifications',
          sound: 'default',
          priority: 'high',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    // Enviar notificação para múltiplos dispositivos
    const response = await admin.messaging().sendEachForMulticast(message);
    
    console.log('✅ Notificações enviadas:', {
      successCount: response.successCount,
      failureCount: response.failureCount,
    });
    
    // Processar tokens inválidos
    if (response.failureCount > 0) {
      const failedTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          failedTokens.push(tokens[idx]);
          console.error('❌ Falha ao enviar para token:', tokens[idx], resp.error);
        }
      });
      
      return {
        success: true,
        successCount: response.successCount,
        failureCount: response.failureCount,
        failedTokens: failedTokens,
      };
    }
    
    return {
      success: true,
      successCount: response.successCount,
      failureCount: 0,
    };
  } catch (error) {
    console.error('❌ Erro ao enviar notificações:', error);
    throw new functions.https.HttpsError('internal', `Erro ao enviar notificações: ${error.message}`);
  }
});

/**
 * Trigger que envia notificação quando uma nova solicitação é criada
 */
exports.notificarNovaSolicitacao = functions.firestore
  .document('alugueis/{aluguelId}')
  .onCreate(async (snapshot, context) => {
    const aluguel = snapshot.data();
    const aluguelId = context.params.aluguelId;

    // Verificar se é uma nova solicitação
    if (aluguel.status !== 'solicitado') {
      return null;
    }

    try {
      // Buscar o FCM token do locador
      const locadorDoc = await admin.firestore()
        .collection('usuarios')
        .doc(aluguel.locadorId)
        .get();

      if (!locadorDoc.exists) {
        console.log('⚠️ Locador não encontrado');
        return null;
      }

      const fcmToken = locadorDoc.data().fcmToken;

      if (!fcmToken) {
        console.log('⚠️ FCM Token não encontrado para o locador');
        return null;
      }

      // Enviar notificação
      const message = {
        token: fcmToken,
        notification: {
          title: 'Nova Solicitação de Aluguel',
          body: `${aluguel.locatarioNome} solicitou alugar seu item "${aluguel.itemNome}"`,
        },
        data: {
          aluguelId: aluguelId,
          tipo: 'nova_solicitacao',
          rota: `/status-aluguel/${aluguelId}`,
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'aluguel_notifications',
            sound: 'default',
          },
        },
      };

      await admin.messaging().send(message);
      console.log('✅ Notificação de nova solicitação enviada');
      
      return null;
    } catch (error) {
      console.error('❌ Erro ao enviar notificação:', error);
      return null;
    }
  });

/**
 * Trigger que envia notificação quando uma solicitação é atualizada
 */
exports.notificarAtualizacaoSolicitacao = functions.firestore
  .document('alugueis/{aluguelId}')
  .onUpdate(async (change, context) => {
    const antes = change.before.data();
    const depois = change.after.data();
    const aluguelId = context.params.aluguelId;

    // Verificar se o status mudou
    if (antes.status === depois.status) {
      return null;
    }

    try {
      let destinatarioId = null;
      let titulo = '';
      let mensagem = '';

      // Determinar destinatário e mensagem baseado na mudança de status
      switch (depois.status) {
        case 'aprovado':
          destinatarioId = depois.locatarioId;
          titulo = 'Solicitação Aprovada! 🎉';
          mensagem = `${depois.locadorNome} aprovou sua solicitação para "${depois.itemNome}"`;
          break;
        
        case 'recusado':
          destinatarioId = depois.locatarioId;
          titulo = 'Solicitação Recusada';
          mensagem = `${depois.locadorNome} recusou sua solicitação para "${depois.itemNome}"`;
          if (depois.motivoRecusaLocador) {
            mensagem += `. Motivo: ${depois.motivoRecusaLocador}`;
          }
          break;
        
        case 'confirmado':
          // Notificar ambos
          titulo = 'Pagamento Confirmado! ✅';
          // Enviar para locador
          await enviarNotificacaoParaUsuario(
            depois.locadorId,
            titulo,
            `Pagamento recebido para o aluguel de "${depois.itemNome}"`,
            aluguelId
          );
          // Enviar para locatário
          await enviarNotificacaoParaUsuario(
            depois.locatarioId,
            titulo,
            `Seu pagamento para "${depois.itemNome}" foi confirmado`,
            aluguelId
          );
          return null;
        
        case 'emAndamento':
          // Notificar ambos que o aluguel começou
          titulo = 'Aluguel Iniciado';
          await enviarNotificacaoParaUsuario(
            depois.locadorId,
            titulo,
            `O aluguel de "${depois.itemNome}" foi iniciado`,
            aluguelId
          );
          await enviarNotificacaoParaUsuario(
            depois.locatarioId,
            titulo,
            `Seu aluguel de "${depois.itemNome}" foi iniciado`,
            aluguelId
          );
          return null;

        case 'devolucaoPendente':
          destinatarioId = depois.locadorId;
          titulo = 'Devolução Solicitada';
          mensagem = `${depois.locatarioNome} solicitou a devolução de "${depois.itemNome}"`;
          break;

        case 'concluido':
          // Notificar ambos
          titulo = 'Aluguel Concluído! ✅';
          await enviarNotificacaoParaUsuario(
            depois.locadorId,
            titulo,
            `O aluguel de "${depois.itemNome}" foi concluído`,
            aluguelId
          );
          await enviarNotificacaoParaUsuario(
            depois.locatarioId,
            titulo,
            `Seu aluguel de "${depois.itemNome}" foi concluído`,
            aluguelId
          );
          return null;

        default:
          return null;
      }

      if (destinatarioId) {
        await enviarNotificacaoParaUsuario(destinatarioId, titulo, mensagem, aluguelId);
      }

      return null;
    } catch (error) {
      console.error('❌ Erro ao enviar notificação:', error);
      return null;
    }
  });

/**
 * Função auxiliar para enviar notificação para um usuário específico
 */
async function enviarNotificacaoParaUsuario(usuarioId, titulo, mensagem, aluguelId) {
  try {
    const userDoc = await admin.firestore()
      .collection('usuarios')
      .doc(usuarioId)
      .get();

    if (!userDoc.exists) {
      console.log('⚠️ Usuário não encontrado:', usuarioId);
      return;
    }

    const fcmToken = userDoc.data().fcmToken;

    if (!fcmToken) {
      console.log('⚠️ FCM Token não encontrado para usuário:', usuarioId);
      return;
    }

    const message = {
      token: fcmToken,
      notification: {
        title: titulo,
        body: mensagem,
      },
      data: {
        aluguelId: aluguelId,
        rota: `/status-aluguel/${aluguelId}`,
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'aluguel_notifications',
          sound: 'default',
        },
      },
    };

    await admin.messaging().send(message);
    console.log('✅ Notificação enviada para usuário:', usuarioId);
  } catch (error) {
    console.error('❌ Erro ao enviar notificação para usuário:', usuarioId, error);
  }
}
