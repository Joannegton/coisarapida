import 'package:coisarapida/core/constants/app_routes.dart';
import 'package:coisarapida/features/autenticacao/domain/entities/status_endereco.dart';
import 'package:coisarapida/features/autenticacao/domain/entities/usuario.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CabecalhoPerfilWidget extends StatelessWidget {
  const CabecalhoPerfilWidget({
    super.key,
    required this.usuario,  
  });

  final Usuario usuario;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final usuarioVerificado = usuario.cpf != null && usuario.cpf!.isNotEmpty && usuario.emailVerificado &&
      usuario.telefone != null && usuario.telefone!.isNotEmpty && usuario.statusEndereco == StatusEndereco.aprovado;

    return ListTile(
      contentPadding: EdgeInsets.only(left: screenWidth * 0.025, bottom: screenWidth * 0.025),
      tileColor: theme.colorScheme.primary,
      leading: CircleAvatar(
        radius: screenWidth * 0.075,
        backgroundColor: theme.colorScheme.onPrimary.withAlpha(25),
        backgroundImage: usuario.fotoUrl != null
            ? NetworkImage(usuario.fotoUrl!)
            : null,
        child: usuario.fotoUrl == null
            ? Icon(
                Icons.person,
                size: screenWidth * 0.075,
                color: theme.colorScheme.onPrimary,
              )
            : null,
      ),
      title: Align(
        alignment: usuarioVerificado ? Alignment.center : Alignment.centerLeft,
        child: Text(
          usuario.nome,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      subtitle: !usuarioVerificado ? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Perfil não verificado',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.orangeAccent,
            ),
          ),
        ],
      ) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(onPressed: () => context.push('${AppRoutes.perfilPublico}/${usuario.id}'), icon: Icon(Icons.visibility_outlined, color: theme.colorScheme.onPrimary, size: screenWidth * 0.06)),
          IconButton(onPressed: () => context.push(AppRoutes.editarPerfil), icon: Icon(Icons.edit_outlined, color: theme.colorScheme.onPrimary, size: screenWidth * 0.06)),
        ],
      ),



    );
  }
}