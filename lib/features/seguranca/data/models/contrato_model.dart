import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/contrato.dart';

/// Model que estende a entidade ContratoDigital
/// Responsável pela conversão entre Firestore e a entidade
class ContratoModel extends ContratoDigital {
  const ContratoModel({
    required super.id,
    required super.aluguelId,
    required super.locatarioId,
    required super.locadorId,
    required super.itemId,
    required super.conteudoHtml,
    required super.criadoEm,
    super.aceiteLocatario,
    super.aceiteLocador,
    required super.versaoContrato,
  });

  /// Cria um ContratoModel a partir de uma entidade ContratoDigital
  factory ContratoModel.fromEntity(ContratoDigital entity) {
    return ContratoModel(
      id: entity.id,
      aluguelId: entity.aluguelId,
      locatarioId: entity.locatarioId,
      locadorId: entity.locadorId,
      itemId: entity.itemId,
      conteudoHtml: entity.conteudoHtml,
      criadoEm: entity.criadoEm,
      aceiteLocatario: entity.aceiteLocatario,
      aceiteLocador: entity.aceiteLocador,
      versaoContrato: entity.versaoContrato,
    );
  }

  /// Cria um ContratoModel a partir de um documento Firestore
  factory ContratoModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Documento ${doc.id} não encontrado ou dados nulos.');
    }

    return ContratoModel(
      id: doc.id,
      aluguelId: data['aluguelId'] as String? ?? '',
      locatarioId: data['locatarioId'] as String? ?? '',
      locadorId: data['locadorId'] as String? ?? '',
      itemId: data['itemId'] as String? ?? '',
      conteudoHtml: data['conteudoHtml'] as String? ?? '',
      criadoEm: (data['criadoEm'] as Timestamp?)?.toDate() ?? DateTime.now(),
      aceiteLocatario: data['aceiteLocatario'] != null 
          ? AceiteContrato.fromMap(data['aceiteLocatario'] as Map<String, dynamic>)
          : (data['aceite'] != null 
              ? AceiteContrato.fromMap(data['aceite'] as Map<String, dynamic>)
              : null),
      aceiteLocador: data['aceiteLocador'] != null 
          ? AceiteContrato.fromMap(data['aceiteLocador'] as Map<String, dynamic>)
          : null,
      versaoContrato: data['versaoContrato'] as String? ?? '1.0',
    );
  }

  /// Converte o model para Map para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'aluguelId': aluguelId,
      'locatarioId': locatarioId,
      'locadorId': locadorId,
      'itemId': itemId,
      'conteudoHtml': conteudoHtml,
      'criadoEm': FieldValue.serverTimestamp(),
      'aceiteLocatario': aceiteLocatario?.toMap(),
      'aceiteLocador': aceiteLocador?.toMap(),
      'versaoContrato': versaoContrato,
    };
  }

  /// Converte o model para Map para atualização no Firestore
  Map<String, dynamic> toMapForUpdate() {
    return {
      'aluguelId': aluguelId,
      'locatarioId': locatarioId,
      'locadorId': locadorId,
      'itemId': itemId,
      'conteudoHtml': conteudoHtml,
      'aceiteLocatario': aceiteLocatario?.toMap(),
      'aceiteLocador': aceiteLocador?.toMap(),
      'versaoContrato': versaoContrato,
    };
  }
}
