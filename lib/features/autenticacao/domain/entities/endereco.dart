class Endereco {
  final String cep;
  final String rua;
  final String numero;
  final String? complemento;
  final String bairro;
  final String cidade;
  final String estado;
  final double? latitude;
  final double? longitude;

  const Endereco({
    required this.cep,
    required this.rua,
    required this.numero,
    this.complemento,
    required this.bairro,
    required this.cidade,
    required this.estado,
    this.latitude,
    this.longitude,
  });
}
