import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider para gerenciar o tema do aplicativo
final temaProvider = StateNotifierProvider<TemaNotifier, ThemeMode>((ref) {
  return TemaNotifier();
});

class TemaNotifier extends StateNotifier<ThemeMode> {
  static const String _chavePreferencia = 'tema_app';

  TemaNotifier() : super(ThemeMode.system) {
    _carregarTema();
  }

  /// Carregar tema salvo nas preferências
  Future<void> _carregarTema() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final temaIndex = prefs.getInt(_chavePreferencia);
      
      if (temaIndex != null) {
        state = ThemeMode.values[temaIndex];
      }
    } catch (e) {
      // Se houver erro, manter tema padrão (system)
    }
  }

  /// Alterar tema
  Future<void> alterarTema(ThemeMode novoTema) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_chavePreferencia, novoTema.index);
      state = novoTema;
    } catch (e) {
      // Se houver erro ao salvar, ainda assim alterar o tema na sessão atual
      state = novoTema;
    }
  }

  /// Alternar entre claro e escuro
  Future<void> alternarTema() async {
    final novoTema = state == ThemeMode.dark 
        ? ThemeMode.light 
        : ThemeMode.dark;
    await alterarTema(novoTema);
  }
}
