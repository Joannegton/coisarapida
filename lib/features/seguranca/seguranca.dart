// Exports do módulo de segurança
// Facilita importações organizadas

// Domain - Entities
export 'domain/entities/contrato.dart';
export 'domain/entities/denuncia.dart';
export 'domain/entities/problema.dart';
export 'domain/entities/verificacao_fotos.dart';
export 'domain/entities/verificacao_telefone.dart';
export 'domain/entities/verificacao_residencia.dart';

// Domain - Repositories
export 'domain/repositories/seguranca_repository.dart';

// Data - Models
export 'data/models/contrato_model.dart';
export 'data/models/denuncia_model.dart';
export 'data/models/problema_model.dart';
export 'data/models/verificacao_fotos_model.dart';
export 'data/models/verificacao_telefone_model.dart';
export 'data/models/verificacao_residencia_model.dart';

// Data - Repositories
export 'data/repositories/seguranca_repository_impl.dart';

// Presentation - Providers
export 'presentation/providers/seguranca_provider.dart';

// Presentation - Pages
export 'presentation/pages/problemas_page.dart';
export 'presentation/pages/reportar_problema_page.dart';
export 'presentation/pages/verificacao_residencia_page.dart';
export 'presentation/pages/verificacao_telefone_page.dart';

// Presentation - Widgets
export 'presentation/widgets/contador_tempo.dart';
export 'presentation/widgets/upload_fotos_verificacao.dart';
