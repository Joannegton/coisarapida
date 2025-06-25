import 'package:coisarapida/core/constants/app_routes.dart';
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
    
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 10, bottom: 10),
      tileColor: theme.colorScheme.primary,
      leading: CircleAvatar(
        radius: 30,
        backgroundColor: theme.colorScheme.onPrimary.withAlpha(25),
        backgroundImage: usuario.fotoUrl != null
            ? NetworkImage(usuario.fotoUrl!)
            : null,
        child: usuario.fotoUrl == null
            ? Icon(
                Icons.person,
                size: 30,
                color: theme.colorScheme.onPrimary,
              )
            : null,
      ),
      title: Text(
        usuario.nome,
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.bold
        ),
      ),
      subtitle: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text( //TODO adicionar perfil incompleto também, caso o email esteja verificado e o perfil incompleto
            usuario.emailVerificado == true
                ? 'Email verificado'
                : 'Email não verificado',
            style: theme.textTheme.bodyMedium?.copyWith(
            color: usuario.emailVerificado ? Colors.greenAccent : Colors.orangeAccent),
          ),
        ]
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(onPressed: () => context.push('${AppRoutes.perfilPublico}/${usuario.id}'), icon: Icon(Icons.visibility_outlined, color: theme.colorScheme.onPrimary,)),
          IconButton(onPressed: () => context.push(AppRoutes.editarPerfil), icon: Icon(Icons.edit_outlined, color: theme.colorScheme.onPrimary)),
        ],
      ),



    );
  }
}