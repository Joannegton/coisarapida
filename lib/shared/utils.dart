class Utils {
  static String formatarDataPorExtenso(DateTime data) {
    final meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return '${data.day} ${meses[data.month - 1]} ${data.year}';
  }

  static String formatarData(DateTime data) {
    return "${data.day}/${data.month}/${data.year}";
  }
    // TODO: pesquisar o pacote `intl` melhor para formatar data.
    // ex: DateFormat.yMd().add_jm().format(dateTime)
  static String formatarDataHora(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year;
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$ano às $hora:$minuto';
  }
}