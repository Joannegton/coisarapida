import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:coisarapida/core/services/location_service.dart';
import 'package:coisarapida/features/autenticacao/presentation/providers/auth_provider.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final userLocationProvider = FutureProvider<Position>((ref) async {
  final usuarioAsync = ref.watch(usuarioAtualStreamProvider);
  final usuario = usuarioAsync.value;

  if (usuario != null && usuario.endereco != null && usuario.endereco!.latitude != null && usuario.endereco!.longitude != null) {
    // Retorna posição baseada no endereço salvo do usuário
    return Position(
      latitude: usuario.endereco!.latitude!,
      longitude: usuario.endereco!.longitude!,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  } else {
    // Fallback: usa GPS se não tiver endereço salvo
    final locationService = ref.watch(locationServiceProvider);
    return await locationService.getCurrentPosition();
  }
});
