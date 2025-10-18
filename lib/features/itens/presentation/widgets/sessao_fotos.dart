import 'package:coisarapida/features/itens/presentation/widgets/seletor_fotos.dart';
import 'package:flutter/material.dart';

class SessaoFotos extends StatelessWidget {
  final List<String> fotosUrls;
  final Function(List<String>) onFotosChanged;
  final int maxFotos;

  const SessaoFotos({
    super.key,
    required this.fotosUrls,
    required this.onFotosChanged,
    this.maxFotos = 5,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: SeletorFotosWidget(
        fotosIniciais: fotosUrls, 
        onFotosChanged: onFotosChanged,
        maxFotos: maxFotos,
      ),
    );
  }
}