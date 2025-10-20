import 'package:coisarapida/features/autenticacao/domain/entities/usuario.dart';
import 'package:coisarapida/features/itens/domain/entities/item.dart';
import 'package:coisarapida/features/perfil/presentation/widgets/item_foto_widget.dart';
import 'package:flutter/material.dart';

class PerfilItensUsuarioWidget extends StatelessWidget {
  final List<Item> itens;
  final Usuario usuario; // Necessário para o "Ver todos" se for implementado aqui
  final ThemeData theme;

  const PerfilItensUsuarioWidget({
    super.key,
    required this.itens,
    required this.usuario,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (itens.isEmpty)
          const Center(child: Text('Nenhum item anunciado por este usuário.')),
        if (itens.isNotEmpty)
          SizedBox(
            height: 175,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: itens.length,
              itemBuilder: (context, index) => ItemFotoWidget(item: itens[index], theme: theme),
            ),
          ),
      ],
    );
  }
}