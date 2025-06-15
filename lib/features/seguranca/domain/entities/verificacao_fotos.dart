/// Entidade para verificação de fotos do item antes/depois do aluguel
class VerificacaoFotos {
  final String id;
  final String aluguelId;
  final String itemId;
  final List<String> fotosAntes;
  final List<String> fotosDepois;
  final DateTime? dataFotosAntes;
  final DateTime? dataFotosDepois;
  final String? observacoesAntes;
  final String? observacoesDepois;
  final bool verificacaoCompleta;

  const VerificacaoFotos({
    required this.id,
    required this.aluguelId,
    required this.itemId,
    required this.fotosAntes,
    required this.fotosDepois,
    this.dataFotosAntes,
    this.dataFotosDepois,
    this.observacoesAntes,
    this.observacoesDepois,
    required this.verificacaoCompleta,
  });

  bool get temFotosAntes => fotosAntes.isNotEmpty;
  bool get temFotosDepois => fotosDepois.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'aluguelId': aluguelId,
      'itemId': itemId,
      'fotosAntes': fotosAntes,
      'fotosDepois': fotosDepois,
      'dataFotosAntes': dataFotosAntes?.millisecondsSinceEpoch,
      'dataFotosDepois': dataFotosDepois?.millisecondsSinceEpoch,
      'observacoesAntes': observacoesAntes,
      'observacoesDepois': observacoesDepois,
      'verificacaoCompleta': verificacaoCompleta,
    };
  }

  factory VerificacaoFotos.fromMap(Map<String, dynamic> map) {
    return VerificacaoFotos(
      id: map['id'] ?? '',
      aluguelId: map['aluguelId'] ?? '',
      itemId: map['itemId'] ?? '',
      fotosAntes: List<String>.from(map['fotosAntes'] ?? []),
      fotosDepois: List<String>.from(map['fotosDepois'] ?? []),
      dataFotosAntes: map['dataFotosAntes'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['dataFotosAntes'])
          : null,
      dataFotosDepois: map['dataFotosDepois'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['dataFotosDepois'])
          : null,
      observacoesAntes: map['observacoesAntes'],
      observacoesDepois: map['observacoesDepois'],
      verificacaoCompleta: map['verificacaoCompleta'] ?? false,
    );
  }
}
