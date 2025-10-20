const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

/**
 * Calcula e atualiza a reputação do usuário
 * Trigger executado quando uma avaliação é criada ou atualizada
 */
exports.calcularReputacaoUsuario = onDocumentWritten('avaliacoes/{avaliacaoId}', async (event) => {
  const db = admin.firestore();

  try {
    // Verificar se é uma criação ou atualização válida
    const change = event.data;
    const avaliacaoData = change.after.exists ? change.after.data() : null;
    const avaliacaoAnterior = change.before.exists ? change.before.data() : null;
      
      // Se foi uma deleção, usar dados da avaliação anterior para recalcular
      let usuarioId;
      if (!avaliacaoData && avaliacaoAnterior) {
        usuarioId = avaliacaoAnterior.avaliadoId;
        console.log('Avaliação foi deletada, recalculando reputação...');
      } else if (avaliacaoData) {
        // Validar dados obrigatórios
        if (!avaliacaoData.avaliadoId || !avaliacaoData.tipoAvaliado || avaliacaoData.nota === undefined) {
          console.error('Dados de avaliação inválidos:', avaliacaoData);
          return;
        }

        // Só processar avaliações de usuário
        if (avaliacaoData.tipoAvaliado !== 'usuario') {
          console.log('Avaliação não é de usuário, ignorando...');
          return;
        }

        usuarioId = avaliacaoData.avaliadoId;
      } else {
        console.log('Nenhum dado válido encontrado para processamento');
        return;
      }

      console.log(`🧮 Calculando reputação para usuário: ${usuarioId}`);

      // Buscar todas as avaliações válidas do usuário no Firestore
      const avaliacoesSnapshot = await db
        .collection('avaliacoes')
        .where('avaliadoId', '==', usuarioId)
        .where('tipoAvaliado', '==', 'usuario')
        .where('visivel', '==', true)
        .get();

      let somaNotas = 0;
      let totalAvaliacoes = 0;

      avaliacoesSnapshot.forEach((doc) => {
        const avaliacao = doc.data();
        // Verificar se não foi deletada (soft delete)
        if (!avaliacao.deletedAt && avaliacao.nota !== undefined && avaliacao.nota >= 0 && avaliacao.nota <= 5) {
          somaNotas += avaliacao.nota;
          totalAvaliacoes++;
        }
      });

      // Calcular nova reputação
      const novaReputacao = totalAvaliacoes > 0 ? (somaNotas / totalAvaliacoes) : 0;
      const reputacaoFormatada = Math.round(novaReputacao * 100) / 100; // 2 casas decimais

      console.log(`📊 Usuário ${usuarioId}: ${totalAvaliacoes} avaliações, reputação: ${reputacaoFormatada}`);

      // Atualizar no documento do usuário no Firestore
      const userDocRef = db.collection('usuarios').doc(usuarioId);
      const userDoc = await userDocRef.get();

      if (userDoc.exists) {
        await userDocRef.update({
          reputacao: reputacaoFormatada,
          totalAvaliacoes: totalAvaliacoes,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log(`✅ Reputação atualizada no Firestore para usuário ${usuarioId}`);
      } else {
        console.warn(`⚠️ Usuário ${usuarioId} não encontrado no Firestore`);
        return;
      }

      // Também atualizar estatísticas nos itens do usuário (opcional)
      const itensSnapshot = await db
        .collection('itens')
        .where('proprietarioId', '==', usuarioId)
        .get();

      if (!itensSnapshot.empty) {
        const batch = db.batch();
        
        itensSnapshot.forEach((doc) => {
          batch.update(doc.ref, {
            proprietarioReputacao: reputacaoFormatada,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        });

        await batch.commit();
        console.log(`✅ Reputação atualizada em ${itensSnapshot.size} itens do usuário ${usuarioId}`);
      }

      console.log(`✅ Reputação calculada e atualizada para usuário ${usuarioId}: ${reputacaoFormatada} (${totalAvaliacoes} avaliações)`);

  } catch (error) {
    console.error('❌ Erro ao calcular reputação do usuário:', error);
    // Em triggers Firestore, não lançamos HttpsError, apenas logamos
  }
});

/**
 * Recalcula a reputação de todos os usuários
 * Função HTTP para manutenção/correção de dados
 */
exports.recalcularTodasReputacoes = onCall(async (request) => {
  // Verificar se o usuário está autenticado (opcional: adicionar verificação de admin)
  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'Usuário deve estar autenticado para executar esta função'
    );
  }

  const db = admin.firestore();

  try {
    console.log('🔄 Iniciando recálculo de todas as reputações...');

    // Buscar todos os usuários ativos no Firestore
    const usuariosSnapshot = await db
      .collection('usuarios')
      .where('ativo', '==', true)
      .get();

    let processados = 0;
    let erros = 0;

    console.log(`📊 Processando ${usuariosSnapshot.size} usuários...`);

    // Processar cada usuário
    for (const userDoc of usuariosSnapshot.docs) {
      try {
        const usuarioId = userDoc.id;

        // Buscar avaliações do usuário
        const avaliacoesSnapshot = await db
          .collection('avaliacoes')
          .where('avaliadoId', '==', usuarioId)
          .where('tipoAvaliado', '==', 'usuario')
          .where('visivel', '==', true)
          .get();

        let somaNotas = 0;
        let totalAvaliacoes = 0;

        avaliacoesSnapshot.forEach((doc) => {
          const avaliacao = doc.data();
          // Verificar se não foi deletada (soft delete)
          if (!avaliacao.deletedAt && avaliacao.nota !== undefined && avaliacao.nota >= 0 && avaliacao.nota <= 5) {
            somaNotas += avaliacao.nota;
            totalAvaliacoes++;
          }
        });

        const novaReputacao = totalAvaliacoes > 0 ? (somaNotas / totalAvaliacoes) : 0;
        const reputacaoFormatada = Math.round(novaReputacao * 100) / 100;

        // Atualizar no Firestore
        await userDoc.ref.update({
          reputacao: reputacaoFormatada,
          totalAvaliacoes: totalAvaliacoes,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // Atualizar também nos itens do usuário
        const itensSnapshot = await db
          .collection('itens')
          .where('proprietarioId', '==', usuarioId)
          .get();

        if (!itensSnapshot.empty) {
          const batch = db.batch();
          
          itensSnapshot.forEach((doc) => {
            batch.update(doc.ref, {
              proprietarioReputacao: reputacaoFormatada,
              updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
          });

          await batch.commit();
        }

        processados++;
        
        if (processados % 10 === 0) {
          console.log(`🔄 Processados ${processados}/${usuariosSnapshot.size} usuários...`);
        }

      } catch (userError) {
        console.error(`❌ Erro ao processar usuário ${userDoc.id}:`, userError);
        erros++;
      }
    }

    const resultado = {
      success: true,
      message: `Recálculo concluído: ${processados} usuários processados, ${erros} erros`,
      processados,
      erros,
      total: usuariosSnapshot.size
    };

    console.log(`✅ ${resultado.message}`);
    return resultado;

  } catch (error) {
    console.error('❌ Erro ao recalcular reputações:', error);
    throw new HttpsError(
      'internal',
      'Erro ao recalcular reputações',
      error.message
    );
  }
});

/**
 * Calcula estatísticas de avaliação para um usuário específico
 * Função HTTP callable
 */
exports.obterEstatisticasAvaliacoes = onCall(async (request) => {
  if (!request.data.usuarioId) {
    throw new HttpsError(
      'invalid-argument',
      'usuarioId é obrigatório'
    );
  }

  const db = admin.firestore();

  try {
    const usuarioId = request.data.usuarioId;

    // Buscar todas as avaliações do usuário
    const avaliacoesSnapshot = await db
      .collection('avaliacoes')
      .where('avaliadoId', '==', usuarioId)
      .where('tipoAvaliado', '==', 'usuario')
      .where('visivel', '==', true)
      .orderBy('createdAt', 'desc')
      .get();

    const avaliacoes = [];
    let somaNotas = 0;
    const distribuicaoNotas = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };

    avaliacoesSnapshot.forEach((doc) => {
      const avaliacao = doc.data();
      
      // Verificar se não foi deletada (soft delete)
      if (!avaliacao.deletedAt && avaliacao.nota !== undefined && avaliacao.nota >= 0 && avaliacao.nota <= 5) {
        avaliacoes.push({
          id: doc.id,
          ...avaliacao
        });
        
        somaNotas += avaliacao.nota;
        
        const notaInt = Math.round(avaliacao.nota);
        if (notaInt >= 1 && notaInt <= 5) {
          distribuicaoNotas[notaInt]++;
        }
      }
    });

    const totalAvaliacoes = avaliacoes.length;
    const reputacaoMedia = totalAvaliacoes > 0 ? (somaNotas / totalAvaliacoes) : 0;

    return {
      usuarioId,
      totalAvaliacoes,
      reputacaoMedia: Math.round(reputacaoMedia * 100) / 100,
      distribuicaoNotas,
      avaliacoesRecentes: avaliacoes.slice(0, 5), // Últimas 5 avaliações
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    };

  } catch (error) {
    console.error('❌ Erro ao obter estatísticas de avaliações:', error);
    throw new HttpsError(
      'internal',
      'Erro ao obter estatísticas de avaliações',
      error.message
    );
  }
});