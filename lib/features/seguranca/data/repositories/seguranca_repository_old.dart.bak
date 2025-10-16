import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coisarapida/core/errors/exceptions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:convert';

// import '../../domain/entities/caucao.dart'; // Não mais necessário
import '../../domain/entities/contrato.dart';
import '../../domain/entities/denuncia.dart';
import '../../domain/entities/verificacao_fotos.dart';
import '../../domain/entities/problema.dart';

/// Repositório responsável por todas as operações de segurança
class SegurancaRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  SegurancaRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  // ==================== CAUÇÃO ====================

  /* /// Obtém dados da caução para um aluguel - REMOVIDO
  Future<Caucao?> obterCaucao(String aluguelId) async {
    try {
      // Busca a caução pelo aluguelId. Pode haver várias cauções para um aluguelId
      // se a lógica permitir (ex: uma cancelada e uma nova).
      // Aqui, vamos assumir que queremos a mais recente ou uma específica.
      // Para simplificar, buscaremos uma caução que tenha o aluguelId.
      // Em um cenário real, você pode ter um ID de caução direto ou uma query mais específica.
      final querySnapshot = await _firestore.collection('caucoes').where('aluguelId', isEqualTo: aluguelId).limit(1).get();
      if (querySnapshot.docs.isNotEmpty) {
        return Caucao.fromMap(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      throw ServerException('Erro ao obter caução: $e');
    }
  } */

  /* /// Processa o pagamento da caução - MOVIDO PARA ALUGUEL REPOSITORY
  Future<void> processarCaucao({
    required String aluguelId,
    required String metodoPagamento,
    required double valorCaucao,
  }) async {
    try {
      // Aqui seria a integração real com gateway de pagamento
      // A simulação do Future.delayed pode ser mantida se o processamento do gateway for assíncrono
      // e você quiser simular essa espera.
      await Future.delayed(const Duration(seconds: 2)); // Simulação de processamento
      final transacaoId = 'TXN_${Random().nextInt(999999)}';
      
      // Para processar, assumimos que a caução já existe e tem um ID.
      // O ID 'caucao_$aluguelId' é uma convenção que você pode estar usando,
      // mas certifique-se que este é o ID real do documento da caução.
      // Se a caução é criada com um ID único (como em criarCaucao),
      // você precisaria desse ID único aqui.
      // Por ora, manterei sua lógica de ID, mas é um ponto de atenção.
      final docRef = _firestore.collection('caucoes').doc('caucao_$aluguelId');

      // Atualizar status no Firestore
      await docRef.update({ // Usar update para modificar um documento existente
        'metodoPagamento': metodoPagamento,
        // 'valorCaucao': valorCaucao, // Geralmente o valor da caução não muda após a criação
        'status': StatusCaucao.bloqueada.toString().split('.').last,
        'transacaoId': transacaoId,
        'processadoEm': FieldValue.serverTimestamp(), // Usar timestamp do servidor
      }); // Se o documento não existir, update falhará. Se a intenção é criar se não existir, use set com merge.
    } catch (e) {
      throw ServerException('Erro ao processar caução: $e');
    }
  } */

  /* /// Cria uma nova caução e bloqueia o valor - REMOVIDO
  Future<Caucao> criarCaucao({
    required String aluguelId,
    required String locatarioId,
    required String locadorId,
    required String itemId,
    required double valor,
  }) async {
    try {
      if (valor <= 0) {
        throw ArgumentError('O valor da caução deve ser positivo.');
      }

      final caucaoId = _firestore.collection('caucoes').doc().id;
      
      // Simular bloqueio do valor (integração com gateway de pagamento)
      final transacaoId = await _bloquearValorCaucao(valor, locatarioId);
      
      final caucao = Caucao(
        id: caucaoId,
        aluguelId: aluguelId,
        locatarioId: locatarioId,
        locadorId: locadorId,
        itemId: itemId,
        nomeItem: 'Item Exemplo',
        valorCaucao: valor,
        valorAluguel: 0.0,
        diasAluguel: 1,
        status: StatusCaucao.bloqueada,
        // dataCriacao será definida pelo FieldValue.serverTimestamp() no toMapForCreate
        dataCriacao: DateTime.fromMillisecondsSinceEpoch(0), // Placeholder, não será usado se toMapForCreate for chamado
      );

      await _firestore
          .collection('caucoes')
          .doc(caucaoId)
          .set(caucao.toMapForCreate()); // Usar o método específico para criação

      return caucao;
    } catch (e) {
      throw ServerException('Erro ao criar caução: $e');
    }
  } */

  /* /// Libera a caução após devolução aprovada - MOVIDO PARA ALUGUEL REPOSITORY
  Future<void> liberarCaucao(String caucaoId, String motivo) async {
    try {
      final caucaoDoc = await _firestore.collection('caucoes').doc(caucaoId).get();
      
      if (!caucaoDoc.exists) {
        throw ServerException('Caução não encontrada');
      }

      await _firestore.collection('caucoes').doc(caucaoId).update({
        'status': StatusCaucao.liberada.toString().split('.').last,
        'dataLiberacao': FieldValue.serverTimestamp(), // Usar timestamp do servidor
        'motivoBloqueio': motivo,
      });
    } catch (e) {
      throw ServerException('Erro ao liberar caução: $e');
    }
  } */

  // ==================== CONTRATOS ====================

  /// Gera contrato digital para o aluguel
  Future<ContratoDigital> gerarContrato({
    required String aluguelId,
    required String locatarioId,
    required String locadorId,
    required String itemId,
    required Map<String, dynamic> dadosAluguel,
  }) async {
    try {
      final contratoId = _firestore.collection('contratos').doc().id;
      
      final conteudoHtml = _gerarConteudoContrato(dadosAluguel);
      
      final contrato = ContratoDigital(
        id: contratoId,
        aluguelId: aluguelId,
        locatarioId: locatarioId,
        locadorId: locadorId,
        itemId: itemId,
        conteudoHtml: conteudoHtml,
        criadoEm: DateTime.now(),
        versaoContrato: '1.0',
      );

      await _firestore
          .collection('contratos')
          .doc(contratoId)
          .set(contrato.toMap());

      return contrato;
    } catch (e) {
      throw ServerException('Erro ao gerar contrato: $e');
    }
  }

  /// Registra aceite do contrato
  Future<void> aceitarContrato(String contratoId) async {
    try {
      const enderecoIp = '192.168.1.1';
      const userAgent = 'Flutter App';
      final assinaturaDigital = _gerarAssinaturaDigital(contratoId, enderecoIp);
      
      final aceite = AceiteContrato(
        dataHora: DateTime.now(),
        enderecoIp: enderecoIp,
        userAgent: userAgent,
        assinaturaDigital: assinaturaDigital,
      );

      await _firestore.collection('contratos').doc(contratoId).update({
        'aceite': aceite.toMap(),
      });
    } catch (e) {
      throw ServerException('Erro ao aceitar contrato: $e');
    }
  }

  // ==================== DENÚNCIAS ====================

  /// Cria uma nova denúncia
  Future<Denuncia> criarDenuncia({
    required String aluguelId,
    required String denuncianteId,
    required String denunciadoId,
    required TipoDenuncia tipo,
    required String descricao, // Alterado para List<File> para clareza, mas o provider já espera List<File>
    required List<File> evidencias,
  }) async {
    try {
      final denunciaId = _firestore.collection('denuncias').doc().id;
      final List<String> urlsEvidencias = await _uploadFilesToStorage(evidencias, 'denuncias/$denunciaId');

      final denuncia = Denuncia(
        id: denunciaId,
        aluguelId: aluguelId,
        denuncianteId: denuncianteId,
        denunciadoId: denunciadoId,
        tipo: tipo,
        descricao: descricao,
        evidencias: urlsEvidencias,
        status: StatusDenuncia.pendente,
        criadaEm: DateTime.now(),
      );

      await _firestore
          .collection('denuncias')
          .doc(denunciaId)
          .set(denuncia.toMap());

      return denuncia;
    } catch (e) {
      throw ServerException('Erro ao criar denúncia: $e');
    }
  }

  // ==================== VERIFICAÇÃO DE FOTOS ====================

  /// Salva fotos de verificação do item
  Future<VerificacaoFotos> salvarFotosVerificacao({
    required String aluguelId,
    required String itemId,
    List<File>? fotosAntes,
    List<File>? fotosDepois,
    String? observacoesAntes,
    String? observacoesDepois,
  }) async {
    try {
      // Buscar o aluguel para obter locatarioId e locadorId
      final aluguelDoc = await _firestore.collection('alugueis').doc(aluguelId).get();
      if (!aluguelDoc.exists) {
        throw ServerException('Aluguel não encontrado');
      }
      final aluguelData = aluguelDoc.data()!;
      final locatarioId = aluguelData['locatarioId'] as String;
      final locadorId = aluguelData['locadorId'] as String;

      // Verificar se já existe uma verificação para este aluguel
      final querySnapshot = await _firestore
          .collection('verificacoes_fotos')
          .where('aluguelId', isEqualTo: aluguelId)
          .limit(1)
          .get();

      String verificacaoId;
      List<String> urlsFotosAntes = [];
      List<String> urlsFotosDepois = [];
      DateTime? dataFotosAntesExistente;
      DateTime? dataFotosDepoisExistente;
      String? observacoesAntesExistente;
      String? observacoesDepoisExistente;

      // Se já existe, carregar dados existentes
      if (querySnapshot.docs.isNotEmpty) {
        verificacaoId = querySnapshot.docs.first.id;
        final dadosExistentes = querySnapshot.docs.first.data();
        urlsFotosAntes = List<String>.from(dadosExistentes['fotosAntes'] ?? []);
        urlsFotosDepois = List<String>.from(dadosExistentes['fotosDepois'] ?? []);
        dataFotosAntesExistente = dadosExistentes['dataFotosAntes'] != null 
            ? DateTime.fromMillisecondsSinceEpoch(dadosExistentes['dataFotosAntes'])
            : null;
        dataFotosDepoisExistente = dadosExistentes['dataFotosDepois'] != null 
            ? DateTime.fromMillisecondsSinceEpoch(dadosExistentes['dataFotosDepois'])
            : null;
        observacoesAntesExistente = dadosExistentes['observacoesAntes'];
        observacoesDepoisExistente = dadosExistentes['observacoesDepois'];
      } else {
        verificacaoId = _firestore.collection('verificacoes_fotos').doc().id;
      }

      // Upload de novas fotos ANTES
      if (fotosAntes != null && fotosAntes.isNotEmpty) {
        urlsFotosAntes = await _uploadFilesToStorage(
          fotosAntes,
          'verificacoes_fotos/$locatarioId/$aluguelId/antes',
        );
        dataFotosAntesExistente = DateTime.now();
        observacoesAntesExistente = observacoesAntes;
      }

      // Upload de novas fotos DEPOIS
      if (fotosDepois != null && fotosDepois.isNotEmpty) {
        urlsFotosDepois = await _uploadFilesToStorage(
          fotosDepois,
          'verificacoes_fotos/$locadorId/$aluguelId/depois',
        );
        dataFotosDepoisExistente = DateTime.now();
        observacoesDepoisExistente = observacoesDepois;
      }

      // Verificar se a verificação está completa (tem fotos antes E depois)
      final verificacaoCompleta = urlsFotosAntes.isNotEmpty && urlsFotosDepois.isNotEmpty;

      final verificacao = VerificacaoFotos(
        id: verificacaoId,
        aluguelId: aluguelId,
        itemId: itemId,
        locatarioId: locatarioId,
        locadorId: locadorId,
        fotosAntes: urlsFotosAntes,
        fotosDepois: urlsFotosDepois,
        dataFotosAntes: dataFotosAntesExistente,
        dataFotosDepois: dataFotosDepoisExistente,
        observacoesAntes: observacoesAntesExistente,
        observacoesDepois: observacoesDepoisExistente,
        verificacaoCompleta: verificacaoCompleta,
      );

      await _firestore
          .collection('verificacoes_fotos')
          .doc(verificacaoId)
          .set(verificacao.toMap(), SetOptions(merge: true));

      return verificacao;
    } catch (e) {
      throw ServerException('Erro ao salvar fotos de verificação: $e');
    }
  }  /// Busca verificação de fotos por aluguel ID
  Future<VerificacaoFotos?> buscarVerificacaoFotos(String aluguelId) async {
    try {
      final querySnapshot = await _firestore
          .collection('verificacoes_fotos')
          .where('aluguelId', isEqualTo: aluguelId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return VerificacaoFotos.fromMap(querySnapshot.docs.first.data());
    } catch (e) {
      throw ServerException('Erro ao buscar verificação de fotos: $e');
    }
  }

  // ==================== MULTAS POR ATRASO ====================

  /// Calcula e aplica multa por atraso
  Future<double> calcularMultaAtraso({
    required String aluguelId,
    required String locadorId,
    required DateTime dataLimiteDevolucao,
    required double valorDiaria,
  }) async {
    try {
      final agora = DateTime.now();
      
      if (agora.isBefore(dataLimiteDevolucao)) {
        return 0.0; // Não há atraso
      }
      
      final diasAtraso = agora.difference(dataLimiteDevolucao).inDays;
      const multiplicador = 1.5; // 50% de multa sobre o valor da diária
      final multa = diasAtraso * valorDiaria * multiplicador;
      
      // Debug: Verificar se o usuário autenticado é o locador
      final currentUser = FirebaseAuth.instance.currentUser;
      
      // Registrar multa no Firestore
      await _firestore.collection('multas').add({
        'aluguelId': aluguelId,
        'locadorId': locadorId,
        'diasAtraso': diasAtraso,
        'valorDiaria': valorDiaria,
        'multiplicador': multiplicador,
        'valorMulta': multa,
        'calculadaEm': FieldValue.serverTimestamp(),
      });
      
      return multa;
    } catch (e) {
      throw ServerException('Erro ao calcular multa: $e');
    }
  }

  // ==================== MÉTODOS PRIVADOS ====================

  /// Faz upload de uma lista de arquivos para o Firebase Storage e retorna as URLs de download.
  Future<List<String>> _uploadFilesToStorage(List<File> files, String path) async {
    final List<String> downloadUrls = [];
    for (final file in files) {
      try {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
        final ref = _storage.ref().child(path).child(fileName);
        final uploadTask = ref.putFile(file);
        final snapshot = await uploadTask.whenComplete(() => {});
        final downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      } catch (e) {
        // Considerar como tratar falhas de upload individuais
        print('Erro ao fazer upload do arquivo ${file.path}: $e');
      }
    }
    return downloadUrls;
  }  

  /// Gera conteúdo HTML do contrato
  String _gerarConteudoContrato(Map<String, dynamic> dados) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <title>Contrato de Aluguel - Coisa Rápida</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; }
            .header { text-align: center; margin-bottom: 30px; }
            .clausula { margin-bottom: 15px; }
            .destaque { font-weight: bold; color: #d32f2f; }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>CONTRATO DE ALUGUEL</h1>
            <h2>Coisa Rápida</h2>
        </div>
        
        <div class="clausula">
            <h3>1. PARTES</h3>
            <p><strong>Locador:</strong> ${dados['nomeLocador'] ?? 'Locador'}</p>
            <p><strong>Locatário:</strong> ${dados['nomeLocatario'] ?? 'Locatário'}</p>
        </div>
        
        <div class="clausula">
            <h3>2. OBJETO</h3>
            <p><strong>Item:</strong> ${dados['nomeItem'] ?? 'Item'}</p>
            <p><strong>Descrição:</strong> ${dados['descricaoItem'] ?? 'Descrição do item'}</p>
        </div>
        
        <div class="clausula">
            <h3>3. VALORES</h3>
            <p><strong>Valor do Aluguel:</strong> R\$ ${dados['valorAluguel'] ?? '0,00'}</p>
            <p><strong>Caução:</strong> R\$ ${dados['valorCaucao'] ?? '0,00'}</p>
        </div>
        
        <div class="clausula">
            <h3>4. RESPONSABILIDADES</h3>
            <p class="destaque">O locatário se responsabiliza por:</p>
            <ul>
                <li>Devolver o item nas mesmas condições</li>
                <li>Pagar multa de R\$ ${dados['valorDiaria'] ?? '0,00'} × 1.5 por dia de atraso</li>
                <li>Cobrir custos de danos ou perda total</li>
                <li>Usar o item conforme instruções</li>
            </ul>
        </div>
        
        <div class="clausula">
            <h3>5. CAUÇÃO</h3>
            <p>A caução de R\$ ${dados['valorCaucao'] ?? '0,00'} será:</p>
            <ul>
                <li>Liberada após devolução aprovada</li>
                <li>Utilizada para cobrir danos ou multas</li>
                <li>Não transferida ao locador durante o aluguel</li>
            </ul>
        </div>
        
        <p><strong>Data:</strong> ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}</p>
    </body>
    </html>
    ''';
  }

  /// Gera assinatura digital do aceite
  String _gerarAssinaturaDigital(String contratoId, String ip) {
    final dados = '$contratoId-$ip-${DateTime.now().millisecondsSinceEpoch}';
    final bytes = utf8.encode(dados);
    return base64.encode(bytes);
  }

  // ==================== PROBLEMAS ====================

  /// Cria um novo problema reportado
  Future<Problema> reportarProblema({
    required String aluguelId,
    required String itemId,
    required String reportadoContraId,
    required TipoProblema tipo,
    required PrioridadeProblema prioridade,
    required String descricao,
    List<File>? fotos,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw ServerException('Usuário não autenticado');
      }

      final problemaId = _firestore.collection('problemas').doc().id;
      
      // Upload de fotos se houver
      List<String> urlsFotos = [];
      if (fotos != null && fotos.isNotEmpty) {
        urlsFotos = await _uploadFilesToStorage(
          fotos,
          'problemas/$problemaId',
        );
      }

      // Buscar nome do usuário atual
      final userDoc = await _firestore.collection('usuarios').doc(currentUser.uid).get();
      final userName = userDoc.data()?['nome'] ?? 'Usuário';

      final problema = Problema(
        id: problemaId,
        aluguelId: aluguelId,
        itemId: itemId,
        reportadoPorId: currentUser.uid,
        reportadoPorNome: userName,
        reportadoContraId: reportadoContraId,
        tipo: tipo,
        prioridade: prioridade,
        descricao: descricao,
        fotos: urlsFotos,
        status: StatusProblema.aberto,
        criadoEm: DateTime.now(),
      );

      await _firestore
          .collection('problemas')
          .doc(problemaId)
          .set(problema.toMap());

      return problema;
    } catch (e) {
      throw ServerException('Erro ao reportar problema: $e');
    }
  }

  /// Busca problemas de um aluguel
  Future<List<Problema>> buscarProblemasAluguel(String aluguelId) async {
    try {
      final querySnapshot = await _firestore
          .collection('problemas')
          .where('aluguelId', isEqualTo: aluguelId)
          .orderBy('criadoEm', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Problema.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw ServerException('Erro ao buscar problemas: $e');
    }
  }

  /// Atualiza o status de um problema
  Future<void> atualizarStatusProblema({
    required String problemaId,
    required StatusProblema novoStatus,
    String? resolucao,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': novoStatus.toString().split('.').last,
      };

      if (novoStatus == StatusProblema.resolvido) {
        updates['resolvidoEm'] = DateTime.now().millisecondsSinceEpoch;
        if (resolucao != null) {
          updates['resolucao'] = resolucao;
        }
      }

      await _firestore
          .collection('problemas')
          .doc(problemaId)
          .update(updates);
    } catch (e) {
      throw ServerException('Erro ao atualizar status do problema: $e');
    }
  }

  /// Stream de problemas de um aluguel
  Stream<List<Problema>> problemasAluguelStream(String aluguelId) {
    return _firestore
        .collection('problemas')
        .where('aluguelId', isEqualTo: aluguelId)
        .orderBy('criadoEm', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Problema.fromMap(doc.data()))
            .toList());
  }
}
