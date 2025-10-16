/// Entidade para verificação de fotos do item antes/depois do aluguel
class VerificacaoFotos {
  final String id;
  final String aluguelId;
  final String itemId;
  final String locatarioId;
  final String locadorId;
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
    required this.locatarioId,
    required this.locadorId,
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

  VerificacaoFotos copyWith({
    String? id,
    String? aluguelId,
    String? itemId,
    String? locatarioId,
    String? locadorId,
    List<String>? fotosAntes,
    List<String>? fotosDepois,
    DateTime? dataFotosAntes,
    DateTime? dataFotosDepois,
    String? observacoesAntes,
    String? observacoesDepois,
    bool? verificacaoCompleta,
  }) {
    return VerificacaoFotos(
      id: id ?? this.id,
      aluguelId: aluguelId ?? this.aluguelId,
      itemId: itemId ?? this.itemId,
      locatarioId: locatarioId ?? this.locatarioId,
      locadorId: locadorId ?? this.locadorId,
      fotosAntes: fotosAntes ?? this.fotosAntes,
      fotosDepois: fotosDepois ?? this.fotosDepois,
      dataFotosAntes: dataFotosAntes ?? this.dataFotosAntes,
      dataFotosDepois: dataFotosDepois ?? this.dataFotosDepois,
      observacoesAntes: observacoesAntes ?? this.observacoesAntes,
      observacoesDepois: observacoesDepois ?? this.observacoesDepois,
      verificacaoCompleta: verificacaoCompleta ?? this.verificacaoCompleta,
    );
  }
}
