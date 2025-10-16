import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/verificacao_fotos.dart';

/// Model que estende a entidade VerificacaoFotos
/// Responsável pela conversão entre Firestore e a entidade
class VerificacaoFotosModel extends VerificacaoFotos {
  const VerificacaoFotosModel({
    required super.id,
    required super.aluguelId,
    required super.itemId,
    required super.locatarioId,
    required super.locadorId,
    required super.fotosAntes,
    required super.fotosDepois,
    super.dataFotosAntes,
    super.dataFotosDepois,
    super.observacoesAntes,
    super.observacoesDepois,
    required super.verificacaoCompleta,
  });

  /// Cria um VerificacaoFotosModel a partir de uma entidade VerificacaoFotos
  factory VerificacaoFotosModel.fromEntity(VerificacaoFotos entity) {
    return VerificacaoFotosModel(
      id: entity.id,
      aluguelId: entity.aluguelId,
      itemId: entity.itemId,
      locatarioId: entity.locatarioId,
      locadorId: entity.locadorId,
      fotosAntes: entity.fotosAntes,
      fotosDepois: entity.fotosDepois,
      dataFotosAntes: entity.dataFotosAntes,
      dataFotosDepois: entity.dataFotosDepois,
      observacoesAntes: entity.observacoesAntes,
      observacoesDepois: entity.observacoesDepois,
      verificacaoCompleta: entity.verificacaoCompleta,
    );
  }

  /// Cria um VerificacaoFotosModel a partir de um documento Firestore
  factory VerificacaoFotosModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Documento ${doc.id} não encontrado ou dados nulos.');
    }

    return VerificacaoFotosModel(
      id: doc.id,
      aluguelId: data['aluguelId'] as String? ?? '',
      itemId: data['itemId'] as String? ?? '',
      locatarioId: data['locatarioId'] as String? ?? '',
      locadorId: data['locadorId'] as String? ?? '',
      fotosAntes: List<String>.from(data['fotosAntes'] as List? ?? []),
      fotosDepois: List<String>.from(data['fotosDepois'] as List? ?? []),
      dataFotosAntes: (data['dataFotosAntes'] as Timestamp?)?.toDate(),
      dataFotosDepois: (data['dataFotosDepois'] as Timestamp?)?.toDate(),
      observacoesAntes: data['observacoesAntes'] as String?,
      observacoesDepois: data['observacoesDepois'] as String?,
      verificacaoCompleta: data['verificacaoCompleta'] as bool? ?? false,
    );
  }

  /// Converte o model para Map para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'aluguelId': aluguelId,
      'itemId': itemId,
      'locatarioId': locatarioId,
      'locadorId': locadorId,
      'fotosAntes': fotosAntes,
      'fotosDepois': fotosDepois,
      'dataFotosAntes': dataFotosAntes != null ? Timestamp.fromDate(dataFotosAntes!) : null,
      'dataFotosDepois': dataFotosDepois != null ? Timestamp.fromDate(dataFotosDepois!) : null,
      'observacoesAntes': observacoesAntes,
      'observacoesDepois': observacoesDepois,
      'verificacaoCompleta': verificacaoCompleta,
    };
  }

  /// Converte o model para Map para atualização no Firestore
  Map<String, dynamic> toMapForUpdate() {
    return {
      'fotosAntes': fotosAntes,
      'fotosDepois': fotosDepois,
      'dataFotosAntes': dataFotosAntes != null ? Timestamp.fromDate(dataFotosAntes!) : null,
      'dataFotosDepois': dataFotosDepois != null ? Timestamp.fromDate(dataFotosDepois!) : null,
      'observacoesAntes': observacoesAntes,
      'observacoesDepois': observacoesDepois,
      'verificacaoCompleta': verificacaoCompleta,
    };
  }
}
