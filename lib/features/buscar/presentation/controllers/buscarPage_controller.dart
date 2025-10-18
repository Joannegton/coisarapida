import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado da busca na página de busca
class BuscarPageState {
  final String termoBusca;
  final String? categoriaSelecionada;
  final double distanciaMaxima;
  final RangeValues faixaPreco;
  final double avaliacaoMinima;
  final bool apenasDisponiveis;
  final String ordenarPor;

  BuscarPageState({
    this.termoBusca = '',
    this.categoriaSelecionada = 'todos',
    this.distanciaMaxima = 50.0, // Aumentar para não filtrar por distância inicialmente
    this.faixaPreco = const RangeValues(0, 1000), // Aumentar faixa de preço
    this.avaliacaoMinima = 0.0,
    this.apenasDisponiveis = false, // Mudar para false para mostrar todos inicialmente
    this.ordenarPor = 'distancia',
  });

  BuscarPageState copyWith({
    String? termoBusca,
    String? categoriaSelecionada,
    double? distanciaMaxima,
    RangeValues? faixaPreco,
    double? avaliacaoMinima,
    bool? apenasDisponiveis,
    String? ordenarPor,
  }) {
    return BuscarPageState(
      termoBusca: termoBusca ?? this.termoBusca,
      categoriaSelecionada: categoriaSelecionada ?? this.categoriaSelecionada,
      distanciaMaxima: distanciaMaxima ?? this.distanciaMaxima,
      faixaPreco: faixaPreco ?? this.faixaPreco,
      avaliacaoMinima: avaliacaoMinima ?? this.avaliacaoMinima,
      apenasDisponiveis: apenasDisponiveis ?? this.apenasDisponiveis,
      ordenarPor: ordenarPor ?? this.ordenarPor,
    );
  }
}

/// Controller para gerenciar o estado da página de busca
class BuscarPageController extends Notifier<BuscarPageState> {
  @override
  BuscarPageState build() {
    return BuscarPageState();
  }

  void setTermoBusca(String termo) {
    state = state.copyWith(termoBusca: termo);
  }

  void setCategoria(String categoria) {
    state = state.copyWith(categoriaSelecionada: categoria);
  }

  void setDistanciaMaxima(double distancia) {
    state = state.copyWith(distanciaMaxima: distancia);
  }

  void setFaixaPreco(RangeValues faixa) {
    state = state.copyWith(faixaPreco: faixa);
  }

  void setAvaliacaoMinima(double avaliacao) {
    state = state.copyWith(avaliacaoMinima: avaliacao);
  }

  void setApenasDisponiveis(bool apenas) {
    state = state.copyWith(apenasDisponiveis: apenas);
  }

  void setOrdenarPor(String ordem) {
    state = state.copyWith(ordenarPor: ordem);
  }

  void limparFiltros() {
    state = BuscarPageState();
  }
}

/// Provider do controller de busca
final buscarPageControllerProvider =
    NotifierProvider<BuscarPageController, BuscarPageState>(() {
  return BuscarPageController();
});

/// RangeValues para compatibilidade - removido, usando do Material
