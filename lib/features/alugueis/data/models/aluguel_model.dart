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
    super.caucaoValor,
    required super.status,
    required super.criadoEm,
    super.atualizadoEm,
    super.observacoesLocatario,
    super.motivoRecusaLocador,
    super.contratoId,
    super.caucaoStatus,
    super.caucaoMetodoPagamento,
    super.caucaoTransacaoId,
    super.caucaoDataBloqueio,
    super.caucaoDataLiberacao,
    super.caucaoMotivoRetencao,
    super.caucaoValorRetido,
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
      caucaoValor: entity.caucaoValor,
      status: entity.status,
      criadoEm: entity.criadoEm,
      atualizadoEm: entity.atualizadoEm,
      observacoesLocatario: entity.observacoesLocatario,
      motivoRecusaLocador: entity.motivoRecusaLocador,
      contratoId: entity.contratoId,
      caucaoStatus: entity.caucaoStatus,
      caucaoMetodoPagamento: entity.caucaoMetodoPagamento,
      caucaoTransacaoId: entity.caucaoTransacaoId,
      caucaoDataBloqueio: entity.caucaoDataBloqueio,
      caucaoDataLiberacao: entity.caucaoDataLiberacao,
      caucaoMotivoRetencao: entity.caucaoMotivoRetencao,
      caucaoValorRetido: entity.caucaoValorRetido,
    );
  }

  factory AluguelModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw FormatException("Dados nulos para o documento Aluguel com ID: ${doc.id}");
    }

    T getField<T>(String key, {T? defaultValue, bool isRequired = true}) {
      final value = data[key];
      if (value == null) {
        if (isRequired && defaultValue == null) {
          throw FormatException("Campo obrigatório '$key' está nulo no documento Aluguel com ID: ${doc.id}");
        }
        return defaultValue as T;
      }
      if (value is! T) {
        if (T == double && value is num) {
          return value.toDouble() as T;
        }
        throw FormatException(
            "Campo '$key' com tipo inesperado. Esperado: $T, Recebido: ${value.runtimeType} no documento Aluguel com ID: ${doc.id}");
      }
      return value;
    }

    DateTime getTimestampField(String key, {bool isRequired = true}) {
      final value = data[key];
      if (value == null) {
        if (isRequired) {
          throw FormatException("Campo Timestamp obrigatório '$key' está nulo no documento Aluguel com ID: ${doc.id}");
        }
        // Se não for obrigatório e nulo, poderia retornar um DateTime padrão ou null, mas a entidade espera DateTime.
        // Para campos de data opcionais na entidade, a lógica precisaria ser ajustada.
        // Por ora, se não for obrigatório e nulo, lançamos erro se a entidade não permitir null.
        // Se a entidade permitir null, o _getField lidaria com isso se T fosse DateTime?
        throw FormatException("Campo Timestamp opcional '$key' está nulo, mas a entidade espera DateTime não nulo. Doc ID: ${doc.id}");
      }
      if (value is! Timestamp) {
        throw FormatException(
            "Campo '$key' não é um Timestamp. Recebido: ${value.runtimeType} no documento Aluguel com ID: ${doc.id}");
      }
      return value.toDate();
    }

    return AluguelModel(
      id: doc.id,
      itemId: getField<String>('itemId'),
      itemNome: getField<String>('itemNome'),
      itemFotoUrl: getField<String>('itemFotoUrl', defaultValue: ''),
      locadorId: getField<String>('locadorId'),
      locadorNome: getField<String>('locadorNome'),
      locatarioId: getField<String>('locatarioId'),
      locatarioNome: getField<String>('locatarioNome'),
      dataInicio: getTimestampField('dataInicio'),
      dataFim: getTimestampField('dataFim'),
      precoTotal: getField<double>('precoTotal'),
      caucaoValor: getField<double?>('caucaoValor', isRequired: false),
      status: StatusAluguel.values.firstWhere(
        (e) => e.name == getField<String>('status', defaultValue: StatusAluguel.solicitado.name),
        orElse: () => StatusAluguel.solicitado, // Fallback caso o valor não seja um enum válido
      ),
      criadoEm: getTimestampField('criadoEm'),
      atualizadoEm: data['atualizadoEm'] != null ? getTimestampField('atualizadoEm', isRequired: false) : null,
      observacoesLocatario: getField<String?>('observacoesLocatario', isRequired: false),
      motivoRecusaLocador: getField<String?>('motivoRecusaLocador', isRequired: false),
      contratoId: getField<String?>('contratoId', isRequired: false),
      caucaoStatus: data['caucaoStatus'] != null
          ? StatusCaucaoAluguel.values.firstWhere((e) => e.name == data['caucaoStatus'], orElse: () => StatusCaucaoAluguel.naoAplicavel)
          : null,
      caucaoMetodoPagamento: getField<String?>('caucaoMetodoPagamento', isRequired: false),
      caucaoTransacaoId: getField<String?>('caucaoTransacaoId', isRequired: false),
      caucaoDataBloqueio: data['caucaoDataBloqueio'] != null ? getTimestampField('caucaoDataBloqueio', isRequired: false) : null,
      caucaoDataLiberacao: data['caucaoDataLiberacao'] != null ? getTimestampField('caucaoDataLiberacao', isRequired: false) : null,
      caucaoMotivoRetencao: getField<String?>('caucaoMotivoRetencao', isRequired: false),
      caucaoValorRetido: getField<double?>('caucaoValorRetido', isRequired: false),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // 'id' não é salvo no mapa, pois é o ID do documento
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
      'caucaoValor': caucaoValor,
      'status': status.name,
      'criadoEm': FieldValue.serverTimestamp(), // Definido na criação
      'atualizadoEm': FieldValue.serverTimestamp(), // Atualizado em cada modificação
      'observacoesLocatario': observacoesLocatario,
      'motivoRecusaLocador': motivoRecusaLocador,
      'contratoId': contratoId,
      'caucaoStatus': caucaoStatus?.name,
      'caucaoMetodoPagamento': caucaoMetodoPagamento,
      'caucaoTransacaoId': caucaoTransacaoId,
      'caucaoDataBloqueio': caucaoDataBloqueio != null ? Timestamp.fromDate(caucaoDataBloqueio!) : null,
      'caucaoDataLiberacao': caucaoDataLiberacao != null ? Timestamp.fromDate(caucaoDataLiberacao!) : null,
      'caucaoMotivoRetencao': caucaoMotivoRetencao,
      'caucaoValorRetido': caucaoValorRetido,
      'participantes': [locadorId, locatarioId], // Para facilitar queries
    };
  }
}