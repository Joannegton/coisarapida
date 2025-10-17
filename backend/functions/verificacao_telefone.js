const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const { logger } = require('firebase-functions');
const admin = require('firebase-admin');
const { FieldValue } = require('firebase-admin/firestore');
const twilio = require('twilio');

if (!admin.apps.length) {
  admin.initializeApp();
}

if (process.env.FUNCTIONS_EMULATOR) {
  admin.firestore().settings({
    host: 'localhost:8080',
    ssl: false,
  });
}

// Definir secrets para as credenciais do Twilio
const twilioAccountSid = process.env.FUNCTIONS_EMULATOR 
  ? { value: () => process.env.TWILIO_ACCOUNT_SID }
  : defineSecret('TWILIO_ACCOUNT_SID');
const twilioAuthToken = process.env.FUNCTIONS_EMULATOR
  ? { value: () => process.env.TWILIO_AUTH_TOKEN }
  : defineSecret('TWILIO_AUTH_TOKEN');
const twilioVerifyServiceSid = process.env.FUNCTIONS_EMULATOR
  ? { value: () => process.env.TWILIO_VERIFY_SERVICE_SID }
  : defineSecret('TWILIO_VERIFY_SERVICE_SID');

/**
 * Enviar código de verificação por SMS
 */
exports.enviarCodigoSMS = onCall(
  { secrets: [twilioAccountSid, twilioAuthToken, twilioVerifyServiceSid] },
  async (data) => {
    console.log('Objeto completo:', JSON.stringify(data.data, null, 2));
    console.log('data.data:', data.data);
    console.log('data.data.telefone:', data.data.telefone);
    const telefone = String(data.data.telefone || '');
    console.log('Telefone após conversão:', telefone);

    // Validar telefone
    let telefoneInternacional;
    try {
      // Assumir que o telefone é brasileiro de 11 dígitos
      if (!/^\d{11}$/.test(telefone)) {
        throw new Error('Telefone inválido');
      }
      telefoneInternacional = "+55" + telefone;
    } catch (error) {
      throw new HttpsError(
        'invalid-argument',
        'Telefone inválido. Use formato válido com DDD.'
      );
    }

    // Rate limiting
    const db = admin.firestore();
    const verificationRef = db.collection('verificacoes_sms').doc(telefoneInternacional);
    const verificationDoc = await verificationRef.get();
    if (verificationDoc.exists) {
      const lastAttempt = verificationDoc.data().lastAttempt?.toDate();
      if (lastAttempt && Date.now() - lastAttempt.getTime() < 30000) {
        throw new HttpsError(
          'resource-exhausted',
          'Aguarde 30 segundos antes de tentar novamente'
        );
      }
    }

    try {
      const client = twilio(twilioAccountSid.value(), twilioAuthToken.value());
      const serviceSid = twilioVerifyServiceSid.value();

      if (!serviceSid) {
        throw new HttpsError(
          'failed-precondition',
          'Serviço de verificação não configurado.'
        );
      }

      const verification = await client.verify.v2
        .services(serviceSid)
        .verifications.create({
          to: telefoneInternacional,
          channel: 'sms',
          locale: 'pt-BR',
        });

      // Atualizar timestamp da última tentativa
      await verificationRef.set(
        { lastAttempt: FieldValue.serverTimestamp() },
        { merge: true }
      );

      return {
        success: true,
        message: 'Código de verificação enviado por SMS',
      };
    } catch (error) {
      logger.error('Erro ao enviar SMS:', error, { code: error.code });
      if (error.code === 60200) {
        throw new HttpsError(
          'invalid-argument',
          'Número de telefone inválido ou não suportado'
        );
      }
      throw new HttpsError(
        'internal',
        `Erro ao enviar SMS: ${error.message || 'Erro desconhecido'}`
      );
    }
  }
);

/**
 * Verificar código SMS enviado
 */
exports.verificarCodigoSMS = onCall(
  { secrets: [twilioAccountSid, twilioAuthToken, twilioVerifyServiceSid] },
  async (data) => {
    // if (!data.auth) {
    //   throw new HttpsError('unauthenticated', 'Usuário não autenticado');
    // } 

    const { codigo, telefone } = data.data;
    const userId = 'Yp02HN8u8xTcgWzqvzlgls4oes93' //data.auth.uid;

    if (!codigo || !/^\d{4,10}$/.test(codigo)) {
      throw new HttpsError('invalid-argument', 'Código inválido');
    }

    let telefoneInternacional;
    try {
      // Assumir que o telefone é brasileiro de 11 dígitos
      if (!/^\d{11}$/.test(telefone)) {
        throw new Error('Telefone inválido');
      }
      telefoneInternacional = "+55" + telefone;
    } catch (error) {
      throw new HttpsError(
        'invalid-argument',
        'Telefone inválido. Use formato válido com DDD.'
      );
    }

    try {
      const client = twilio(twilioAccountSid.value(), twilioAuthToken.value());
      const serviceSid = twilioVerifyServiceSid.value();

      if (!serviceSid) {
        throw new HttpsError('failed-precondition', 'Serviço de verificação não configurado');
      }

      const verification = await client.verify.v2
        .services(serviceSid)
        .verificationChecks.create({
          to: telefoneInternacional,
          code: codigo,
        });

      if (process.env.FUNCTIONS_EMULATOR || verification.status === 'approved') {
        // Em emulador, aceita qualquer status para teste
      } else {
        throw new HttpsError('invalid-argument', 'Código incorreto');
      }

      // Atualizar usuário
      const db = admin.firestore();
      await db.collection('usuarios').doc(userId).set(
        {
          telefone: telefoneInternacional,
        },
        { merge: true }
      );

      // Criar notificação de sucesso
      await db.collection('notificacoes').add({
        usuarioId: userId,
        tipo: 'telefone_verificado',
        titulo: 'Telefone verificado com sucesso! ✅',
        mensagem: 'Seu número de telefone foi verificado',
        lida: false,
        dataCriacao: FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        message: 'Telefone verificado com sucesso!',
      };
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }
      throw new HttpsError('internal', error.message);
    }
  }
);

/**
 * Reenviar código SMS
 */
exports.reenviarCodigoSMS = onCall(
  { secrets: [twilioAccountSid, twilioAuthToken, twilioVerifyServiceSid] },
  async (data) => {
    if (!data.auth) {
      throw new HttpsError('unauthenticated', 'Usuário não autenticado');
    }

    try {
      return await exports.enviarCodigoSMS(data);
    } catch (error) {
      logger.error('Erro ao reenviar SMS:', error);
      if (error instanceof HttpsError) {
        throw error;
      }
      throw new HttpsError('internal', error.message);
    }
  }
);
