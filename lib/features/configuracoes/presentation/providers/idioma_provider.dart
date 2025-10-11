import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider para gerenciar o idioma do aplicativo
final idiomaProvider = StateNotifierProvider<IdiomaNotifier, Locale>((ref) {
  return IdiomaNotifier();
});

class IdiomaNotifier extends StateNotifier<Locale> {
  static const String _chavePreferencia = 'idioma_app';

  IdiomaNotifier() : super(const Locale('pt', 'BR')) {
    _carregarIdioma();
  }

  /// Carregar idioma salvo nas preferências
  Future<void> _carregarIdioma() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final codigoIdioma = prefs.getString(_chavePreferencia);
      
      if (codigoIdioma != null) {
        final partes = codigoIdioma.split('_');
        state = Locale(partes[0], partes.length > 1 ? partes[1] : null);
      }
    } catch (e) {
      // Se houver erro, manter idioma padrão (português)
    }
  }

  /// Alterar idioma
  Future<void> alterarIdioma(Locale novoIdioma) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final codigoIdioma = novoIdioma.countryCode != null
          ? '${novoIdioma.languageCode}_${novoIdioma.countryCode}'
          : novoIdioma.languageCode;
      
      await prefs.setString(_chavePreferencia, codigoIdioma);
      state = novoIdioma;
    } catch (e) {
      // Se houver erro ao salvar, ainda assim alterar o idioma na sessão atual
      state = novoIdioma;
    }
  }
}
