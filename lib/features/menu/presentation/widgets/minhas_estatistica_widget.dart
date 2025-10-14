import 'package:coisarapida/features/autenticacao/domain/entities/usuario.dart';
import 'package:flutter/material.dart';

class MinhasEstatisticaWidget extends StatelessWidget {
  final Usuario usuario;

  const MinhasEstatisticaWidget({
    super.key,
    required this.usuario,

  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Minhas Estatísticas',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenWidth * 0.04),
            
            Row(
              children: [
                Expanded(
                  child: _cardEstatisticaWidget(
                    'Itens Anunciados',
                    usuario.totalItensAlugados.toString(),
                    Icons.inventory,
                    theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _cardEstatisticaWidget(
                    'Aluguéis Realizados',
                    usuario.totalAlugueis.toString(),
                    Icons.handshake,
                    theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: screenWidth * 0.04),
            
            Row(
              children: [
                Expanded(
                  child: _cardEstatisticaWidget(
                    'Avaliação',
                    '${usuario.reputacao.toStringAsFixed(1)} ⭐',
                    Icons.star,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardEstatisticaWidget(String titulo, String valor, IconData icone, Color cor) {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        return Container(
          padding: EdgeInsets.all(screenWidth * 0.04),
          margin: EdgeInsets.all(screenWidth * 0.01),
          decoration: BoxDecoration(
            color: cor.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icone, color: cor, size: screenWidth * 0.06),
              SizedBox(height: screenWidth * 0.02),
              Text(
                valor,
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                  color: cor,
                ),
              ),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: screenWidth * 0.03,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
    );
  }
}