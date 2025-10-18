# Arquitetura Corrigida - CoisaRápida

## 📐 Fluxo de Dados Correto

A arquitetura foi corrigida para seguir o padrão adequado do Riverpod com separação clara de responsabilidades:

```
┌─────────────┐
│   Page      │  ← UI: Exibe dados e captura eventos do usuário
└─────────────┘
       ↓ watch/read
┌─────────────┐
│ Controller  │  ← Estado da UI: Gerencia filtros, inputs e estado local
└─────────────┘
       ↓ read
┌─────────────┐
│  Provider   │  ← Lógica de Negócio: Processa, filtra e transforma dados
└─────────────┘
       ↓ read
┌─────────────┐
│ Repository  │  ← Acesso a Dados: Firebase, API, Database
└─────────────┘
```

## 🔄 Antes vs Depois

### ❌ ANTES (Errado)
```dart
// Page misturava lógica de filtro com UI
class BuscarPage {
  String _categoriaSelecionada = 'todos';
  double _distanciaMaxima = 10.0;
  
  List<Item> _filtrarItens(List<Item> itens) {
    // Lógica de filtro misturada na Page
  }
}

// Controller tentava buscar dados diretamente
class BuscarPageController {
  Future<void> buscarItens() {
    final itens = _ref.read(todosItensProvider);
    // Processamento aqui...
  }
}
```

### ✅ DEPOIS (Correto)
```dart
// 1. CONTROLLER - Gerencia apenas o ESTADO dos filtros
class BuscarPageController extends Notifier<BuscarPageState> {
  void setTermoBusca(String termo) {
    state = state.copyWith(termoBusca: termo);
  }
  
  void setCategoria(String categoria) {
    state = state.copyWith(categoriaSelecionada: categoria);
  }
}

// 2. PROVIDER - Aplica LÓGICA DE NEGÓCIO reativamente
final itensFiltradosBuscaProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final filtros = ref.watch(buscarPageControllerProvider);
  final itensBase = ref.watch(todosItensProximosProvider);
  
  // Aplica filtros
  return itensBase.where((item) {
    // Lógica de filtro aqui
  }).toList();
});

// 3. PAGE - Apenas exibe UI e reage a mudanças
class BuscarPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itensFiltrados = ref.watch(itensFiltradosBuscaProvider);
    // Apenas renderiza UI
  }
}
```

## 📂 Estrutura de Arquivos Criada/Modificada

```
lib/features/
├── buscar/
│   └── presentation/
│       ├── controllers/
│       │   └── buscarPage_controller.dart  ← NOVO: Estado dos filtros
│       ├── providers/
│       │   └── buscar_provider.dart        ← NOVO: Lógica de filtro
│       └── pages/
│           └── buscar_page.dart            ← MODIFICADO: Apenas UI
│
└── home/
    └── presentation/
        └── providers/
            └── itens_provider.dart          ← MODIFICADO: Providers base
```

## 🎯 Responsabilidades Claramente Definidas

### 1. **Page (UI Layer)**
- **Responsabilidade**: Renderizar UI e capturar eventos
- **O que FAZ**:
  - Exibir widgets
  - Capturar inputs do usuário (TextField, botões)
  - Chamar métodos do controller em resposta a eventos
- **O que NÃO FAZ**:
  - ❌ Filtrar ou processar dados
  - ❌ Acessar repositórios diretamente
  - ❌ Manter estado de negócio complexo

```dart
// ✅ BOM
ref.read(buscarPageControllerProvider.notifier).setTermoBusca(texto);

// ❌ RUIM
setState(() => _termoBusca = texto);
```

### 2. **Controller (State Management)**
- **Responsabilidade**: Gerenciar estado da UI
- **O que FAZ**:
  - Armazenar filtros selecionados
  - Atualizar estado local da tela
  - Coordenar mudanças de estado
- **O que NÃO FAZ**:
  - ❌ Buscar dados do repositório
  - ❌ Aplicar lógica de filtro
  - ❌ Processar ou transformar dados

```dart
// ✅ BOM - Controller apenas atualiza estado
void setCategoria(String categoria) {
  state = state.copyWith(categoriaSelecionada: categoria);
}

// ❌ RUIM - Controller não deve buscar dados
Future<void> buscarItens() {
  final itens = await repository.getItens();
}
```

### 3. **Provider (Business Logic)**
- **Responsabilidade**: Processar e transformar dados reativamente
- **O que FAZ**:
  - Aplicar filtros nos dados
  - Ordenar listas
  - Combinar múltiplas fontes de dados
  - Calcular distâncias
- **O que NÃO FAZ**:
  - ❌ Renderizar UI
  - ❌ Acessar diretamente Firebase/API (usa repository)

```dart
// ✅ BOM - Provider aplica lógica
final itensFiltradosBuscaProvider = Provider<List<Map>>((ref) {
  final filtros = ref.watch(buscarPageControllerProvider);
  final itens = ref.watch(todosItensProximosProvider);
  
  return itens.where((item) => 
    item['item'].categoria == filtros.categoriaSelecionada
  ).toList();
});
```

### 4. **Repository (Data Access)**
- **Responsabilidade**: Acessar dados externos
- **O que FAZ**:
  - Queries no Firestore
  - Chamadas HTTP para API
  - Upload de arquivos
- **O que NÃO FAZ**:
  - ❌ Processar ou filtrar dados (apenas retorna bruto)
  - ❌ Manter estado

## 🚀 Fluxo Completo no App

### Exemplo: Buscar Itens por Categoria

#### 1️⃣ **Usuário clica em "Ferramentas"**
```dart
// buscar_page.dart
_buildFiltroRapido('Ferramentas', filtros.categoriaSelecionada == 'ferramentas', () {
  ref.read(buscarPageControllerProvider.notifier).setCategoria('ferramentas');
}),
```

#### 2️⃣ **Controller atualiza o estado**
```dart
// buscarPage_controller.dart
void setCategoria(String categoria) {
  state = state.copyWith(categoriaSelecionada: categoria);
}
```

#### 3️⃣ **Provider reage automaticamente** (Riverpod detecta mudança)
```dart
// buscar_provider.dart
final itensFiltradosBuscaProvider = Provider<List<Map>>((ref) {
  final filtros = ref.watch(buscarPageControllerProvider); // ← Detecta mudança!
  final itensBase = ref.watch(todosItensProximosProvider);
  
  return itensBase.where((itemMap) {
    final item = itemMap['item'] as Item;
    return filtros.categoriaSelecionada == 'todos' || 
           item.categoria == filtros.categoriaSelecionada;
  }).toList();
});
```

#### 4️⃣ **UI se atualiza automaticamente**
```dart
// buscar_page.dart
final itensFiltrados = ref.watch(itensFiltradosBuscaProvider); // ← Lista atualizada!
```

## 📊 Providers Principais

### `todosItensStreamProvider`
- **Fonte**: Firestore (Stream em tempo real)
- **Retorna**: `List<Item>`
- **Ordenação**: Nenhuma (ordem do Firestore: `criadoEm DESC`)

### `itensComDistanciaProvider`
- **Fonte**: `todosItensStreamProvider` + localização do usuário
- **Retorna**: `List<Map<String, dynamic>>` com `{item, distancia}`
- **Processamento**: Calcula distância de cada item

### `todosItensProximosProvider`
- **Fonte**: `itensComDistanciaProvider`
- **Retorna**: `List<Map>` ordenados por distância **ASC**
- **Uso**: Base para home_page e buscar_page

### `itensPeloTipoItemProvider(TipoItem?)`
- **Fonte**: `todosItensProximosProvider`
- **Filtra por**: Aluguel, Venda ou Ambos
- **Mantém ordenação**: Distância ASC

### `itensPeloTermoProvider(String)`
- **Fonte**: `todosItensProximosProvider`
- **Filtra por**: Nome, descrição, categoria
- **Mantém ordenação**: Distância ASC

### `itensFiltradosBuscaProvider`
- **Fonte**: Combina filtros do controller com providers acima
- **Filtra por**: Categoria, distância, preço, avaliação, disponibilidade
- **Ordena por**: Distância, preço ou avaliação (conforme selecionado)

## 🏠 Home Page - Implementação

```dart
// home_page.dart
final tipoFiltro = ref.watch(homeTabFilterProvider); // null, aluguel ou venda

// Se tipoFiltro == null, usa todosItensProximosProvider (ordenado por distância)
// Se tipoFiltro != null, usa itensPeloTipoItemProvider que filtra E mantém ordem
final itensFiltrados = tipoFiltro == null 
    ? ref.watch(todosItensProximosProvider)
    : ref.watch(itensPeloTipoItemProvider(tipoFiltro));
```

**Resultado**: Home sempre mostra itens ordenados por distância ASC, opcionalmente filtrados por tipo.

## 🔍 Buscar Page - Implementação

```dart
// buscar_page.dart
final itensFiltrados = ref.watch(itensFiltradosBuscaProvider);
```

O provider `itensFiltradosBuscaProvider`:
1. Pega filtros do controller (`buscarPageControllerProvider`)
2. Busca itens base (`todosItensProximosProvider` ou `itensPeloTermoProvider`)
3. Aplica filtros avançados (categoria, distância, preço, etc.)
4. Ordena conforme selecionado (padrão: distância ASC)

## ✨ Vantagens da Nova Arquitetura

### 1. **Reatividade Automática**
- Mudança em filtro → Provider recalcula → UI atualiza
- Sem `setState()` manual

### 2. **Separação de Responsabilidades**
- Código organizado e testável
- Cada camada tem função clara

### 3. **Performance**
- Riverpod só recalcula o necessário
- Caching automático de providers

### 4. **Manutenibilidade**
- Adicionar novo filtro: apenas atualizar controller e provider
- Mudar lógica de ordenação: apenas no provider

### 5. **Testabilidade**
- Testar filtros: mockar controller state
- Testar UI: mockar providers
- Testar repository: isoladamente

## 📝 Resumo das Mudanças

### Arquivos Criados
1. `buscar_provider.dart` - Lógica de filtro da busca

### Arquivos Modificados
1. `buscarPage_controller.dart` - Agora gerencia apenas estado dos filtros
2. `itens_provider.dart` - Reorganizado para fluxo unidirecional
3. `buscar_page.dart` - Removida lógica de negócio, apenas UI
4. `home_page.dart` - Ajustado para usar providers corretos

### Código Removido
- ❌ Variáveis de estado locais na Page (`_categoriaSelecionada`, etc.)
- ❌ Método `_filtrarItens()` na Page
- ❌ Lógica de busca no controller

### Código Adicionado
- ✅ `BuscarPageState` class para estado imutável
- ✅ `itensFiltradosBuscaProvider` para lógica de filtro
- ✅ Providers reorganizados para fluxo unidirecional
- ✅ Ordenação por distância ASC em todos os providers base

## 🎓 Conceitos-Chave

### Provider.family
```dart
final itensPeloTermoProvider = Provider.family<List, String>((ref, termo) {
  // 'termo' é o parâmetro que muda
});

// Uso:
ref.watch(itensPeloTermoProvider('busca'));
```

### Notifier vs StateNotifier
- **Notifier**: Para estado imutável (recomendado no Riverpod moderno)
- **StateNotifier**: Antigo, mas ainda funciona

### ref.watch vs ref.read
- **watch**: Reage a mudanças (usa em build)
- **read**: Lê uma vez (usa em callbacks/eventos)

---

**Conclusão**: A arquitetura agora segue o padrão correto com fluxo unidirecional de dados e separação clara entre UI, estado, lógica de negócio e acesso a dados. 🎉
