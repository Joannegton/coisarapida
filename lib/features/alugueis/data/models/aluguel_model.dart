import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/aluguel.dart';

class AluguelModel extends Aluguel {
  AluguelModel({
    required super.id,
    required super.itemId,
    required super.itemNome,
    required super.itemFotoUrl,
    required super.locadorId,
    required super.locadorNome,
    required super.locatarioId,
    required super.locatarioNome,
    required super.dataInicio,
    required super.dataFim,
    required super.precoTotal,
    required super.status,
    required super.criadoEm,
    required super.caucao,
    super.atualizadoEm,
    super.observacoesLocatario,
    super.motivoRecusaLocador,
    super.contratoId,
  });

  factory AluguelModel.fromEntity(Aluguel entity) {
    return AluguelModel(
      id: entity.id,
      itemId: entity.itemId,
      itemNome: entity.itemNome,
      itemFotoUrl: entity.itemFotoUrl,
      locadorId: entity.locadorId,
      locadorNome: entity.locadorNome,
      locatarioId: entity.locatarioId,
      locatarioNome: entity.locatarioNome,
      dataInicio: entity.dataInicio,
      dataFim: entity.dataFim,
      precoTotal: entity.precoTotal,
      status: entity.status,
      criadoEm: entity.criadoEm,
      atualizadoEm: entity.atualizadoEm,
      observacoesLocatario: entity.observacoesLocatario,
      motivoRecusaLocador: entity.motivoRecusaLocador,
      contratoId: entity.contratoId,
      caucao: entity.caucao,
    );
  }

  factory AluguelModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw FormatException("Dados nulos para o documento Aluguel com ID: ${doc.id}");
    }

    return AluguelModel(
      id: doc.id,
      itemId: data['itemId'] ?? '',
      itemNome: data['itemNome'] ?? '',
      itemFotoUrl: data['itemFotoUrl'] ?? '',
      locadorId: data['locadorId'] ?? '',
      locadorNome: data['locadorNome'] ?? '',
      locatarioId: data['locatarioId'] ?? '',
      locatarioNome: data['locatarioNome'] ?? '',
      dataInicio: (data['dataInicio'] as Timestamp).toDate(),
      dataFim: (data['dataFim'] as Timestamp).toDate(),
      precoTotal: (data['precoTotal'] as num).toDouble(),
      status: StatusAluguel.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => StatusAluguel.solicitado,
      ),
      criadoEm: (data['criadoEm'] as Timestamp).toDate(),
      atualizadoEm: data['atualizadoEm'] != null ? (data['atualizadoEm'] as Timestamp).toDate() : null,
      observacoesLocatario: data['observacoesLocatario'],
      motivoRecusaLocador: data['motivoRecusaLocador'],
      contratoId: data['contratoId'],
      caucao: AluguelCaucao.fromMap(data['caucao'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemNome': itemNome,
      'itemFotoUrl': itemFotoUrl,
      'locadorId': locadorId,
      'locadorNome': locadorNome,
      'locatarioId': locatarioId,
      'locatarioNome': locatarioNome,
      'dataInicio': Timestamp.fromDate(dataInicio),
      'dataFim': Timestamp.fromDate(dataFim),
      'precoTotal': precoTotal,
      'status': status.name,
      'criadoEm': criadoEm.isUtc ? Timestamp.fromDate(criadoEm) : FieldValue.serverTimestamp(), // Usa o valor se já existir, senão usa o do servidor
      'atualizadoEm': FieldValue.serverTimestamp(),
      'observacoesLocatario': observacoesLocatario,
      'motivoRecusaLocador': motivoRecusaLocador,
      'contratoId': contratoId,
      'caucao': caucao.toMap(), // Salva o objeto caucao como um mapa aninhado
      'participantes': [locadorId, locatarioId],
    };
  }
}