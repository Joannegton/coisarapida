class Utils {
  static String formatarDataPorExtenso(DateTime data) {
    final meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return '${data.day} ${meses[data.month - 1]} ${data.year}';
  }

  static String formatarData(DateTime data) {
    // Formato D/M/AAAA
    return "${data.day}/${data.month}/${data.year}";
  }
}