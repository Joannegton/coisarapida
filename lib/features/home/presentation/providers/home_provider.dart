import 'package:flutter_riverpod/legacy.dart';

import '../../../itens/domain/entities/item.dart';

final homeTabFilterProvider =
    StateProvider<TipoItem?>((ref) => null); // Inicia com 'Todos'
