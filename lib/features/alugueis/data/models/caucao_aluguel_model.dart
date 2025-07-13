import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coisarapida/features/alugueis/domain/entities/caucao_aluguel.dart';

class CaucaoAluguelModel extends CaucaoAluguel {
  CaucaoAluguelModel({
    required super.valor,
    required super.status,
    super.metodoPagamento,
    super.transacaoId,
    super.dataLiberacao,
    super.valorRetido,
    super.motivoRetencao,
    super.dataBloqueio,
  });

  factory CaucaoAluguelModel.fromEntity(CaucaoAluguel entity) {
    return CaucaoAluguelModel(
      valor: entity.valor,
      status: entity.status,
      metodoPagamento: entity.metodoPagamento,
      transacaoId: entity.transacaoId,
      dataLiberacao: entity.dataLiberacao,
      valorRetido: entity.valorRetido,
      motivoRetencao: entity.motivoRetencao,
      dataBloqueio: entity.dataBloqueio,
    );
  }

  factory CaucaoAluguelModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw const FormatException("Dados nulos para o Caucao");
    }

    DateTime? toDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return CaucaoAluguelModel(
      valor: (data['valor'] as num?)?.toDouble() ?? 0.0,
      status: StatusCaucaoAluguel.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => StatusCaucaoAluguel.naoAplicavel,
      ),
      metodoPagamento: data['metodoPagamento'],
      transacaoId: data['transacaoId'],
      dataBloqueio: toDateTime(data['dataBloqueio']),
      dataLiberacao: toDateTime(data['dataLiberacao']),
      motivoRetencao: data['motivoRetencao'],
      valorRetido: (data['valorRetido'] as num?)?.toDouble(),
    );
  }

  factory CaucaoAluguelModel.fromMap(Map<String, dynamic> data) {
    DateTime? toDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return CaucaoAluguelModel(
      valor: (data['valor'] as num?)?.toDouble() ?? 0.0,
      status: StatusCaucaoAluguel.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => StatusCaucaoAluguel.naoAplicavel,
      ),
      metodoPagamento: data['metodoPagamento'],
      transacaoId: data['transacaoId'],
      dataBloqueio: toDateTime(data['dataBloqueio']),
      dataLiberacao: toDateTime(data['dataLiberacao']),
      motivoRetencao: data['motivoRetencao'],
      valorRetido: (data['valorRetido'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'valor': valor,
      'status': status.name,
      'metodoPagamento': metodoPagamento,
      'transacaoId': transacaoId,
      'dataBloqueio':
          dataBloqueio != null ? Timestamp.fromDate(dataBloqueio!) : null,
      'dataLiberacao':
          dataLiberacao != null ? Timestamp.fromDate(dataLiberacao!) : null,
      'motivoRetencao': motivoRetencao,
      'valorRetido': valorRetido,
    };
  }
}
