import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Testa se os serviços de localização estão habilitados.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Serviços de localização não estão habilitados, não continue
      // acessando a posição e solicite aos usuários do
      // App para habilitar os serviços de localização.
      return Future.error('Serviços de localização estão desabilitados.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissões são negadas, na próxima vez você poderia tentar
        // solicitar permissões novamente (isso também é onde
        // Android's shouldShowRequestPermissionRationale
        // retornou true. De acordo com as diretrizes do Android
        // seu App deve mostrar uma UI explicativa agora.
        return Future.error('Permissões de localização são negadas');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissões são negadas para sempre, lide adequadamente.
      return Future.error(
          'Permissões de localização são permanentemente negadas, não podemos solicitar permissões.');
    }

    // Quando chegamos aqui, permissões são concedidas e podemos
    // continuar acessando a posição do dispositivo.
    return await Geolocator.getCurrentPosition();
  }

  double calcularDistancia(double startLatitude, double startLongitude, double endLatitude, double endLongitude) {
    return Geolocator.distanceBetween(startLatitude, startLongitude, endLatitude, endLongitude) / 1000; // em km
  }
}
