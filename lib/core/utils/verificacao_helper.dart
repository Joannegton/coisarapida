import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/autenticacao/presentation/providers/auth_provider.dart';

/// Helper para verificar se o usuário está 100% verificado
/// NOTA: A partir de agora, as verificações de telefone e endereço são OPCIONAIS
class VerificacaoHelper {
  /// Verifica se o usuário está completamente verificado
  /// NOTA: Verificações de telefone e endereço são opcionais
  /// Retorna sempre true pois não há mais verificações obrigatórias
  static bool usuarioVerificado(WidgetRef ref) {
    // Sempre retorna true pois as verificações são opcionais
    return true;
  }

  /// Mostra dialog informando sobre verificações opcionais
  /// NOTA: Este método não é mais usado pois as verificações são opcionais
  @Deprecated('Verificações são opcionais. Use mostrarDialogVerificacoesOpcionais se necessário.')
  static void mostrarDialogVerificacao(BuildContext context, WidgetRef ref) {
    // Método depreciado - verificações são opcionais
  }

  /// Mostra um banner informativo sobre verificações opcionais
  static Widget? bannerVerificacao(WidgetRef ref, BuildContext context) {
    final authState = ref.watch(usuarioAtualStreamProvider);
    if (!authState.hasValue || authState.value == null) return null;

    final usuario = authState.value!;
    final enderecoVerificado = usuario.enderecoVerificado;
    final telefoneVerificado = usuario.telefoneVerificado;

    // Se está tudo verificado, não mostra banner
    if (enderecoVerificado && telefoneVerificado) return null;

    // Mensagem incentivando a verificação (mas não obrigatória)
    String mensagem = 'Aumente sua confiabilidade! Complete as verificações opcionais';
    IconData icone = Icons.verified_user;
    Color cor = Colors.blue;

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor),
      ),
      child: Row(
        children: [
          Icon(icone, color: cor),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mensagem,
                  style: TextStyle(
                    fontSize: 14,
                    color: cor.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Acesse o menu Mais para verificar',
                  style: TextStyle(
                    fontSize: 12,
                    color: cor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
