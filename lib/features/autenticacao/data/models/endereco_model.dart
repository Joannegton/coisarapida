import 'package:coisarapida/features/autenticacao/domain/entities/endereco.dart';

class EnderecoModel extends Endereco {
  const EnderecoModel({
    required super.cep,
    required super.rua,
    required super.numero,
    super.complemento,
    required super.bairro,
    required super.cidade,
    required super.estado,
    super.latitude,
    super.longitude,
  });

  factory EnderecoModel.fromMap(Map<String, dynamic> map) {
    return EnderecoModel(
      cep: map['cep'] ?? '',
      rua: map['rua'] ?? '',
      numero: map['numero'] ?? '',
      complemento: map['complemento'],
      bairro: map['bairro'] ?? '',
      cidade: map['cidade'] ?? '',
      estado: map['estado'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cep': cep,
      'rua': rua,
      'numero': numero,
      'complemento': complemento,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory EnderecoModel.fromEntity(Endereco entity) {
    return EnderecoModel(
        cep: entity.cep, rua: entity.rua, numero: entity.numero, complemento: entity.complemento, bairro: entity.bairro, cidade: entity.cidade, estado: entity.estado, latitude: entity.latitude, longitude: entity.longitude);
  }
}
