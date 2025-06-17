# CoisaRápida 🚀

**CoisaRápida** é um aplicativo móvel desenvolvido em Flutter com o objetivo de facilitar o aluguel de objetos entre usuários e, potencialmente, coordenar entregas urbanas rápidas. O projeto utiliza Firebase como backend e Riverpod para um gerenciamento de estado eficiente.

## ✨ Funcionalidades Principais

O aplicativo conta com diversas funcionalidades, organizadas em módulos:

**Autenticação:**
*   Login com Email/Senha e Google.
*   Cadastro de novos usuários.
*   Recuperação de senha.
*   Tela de Splash animada.
*   Atualização de perfil do usuário (nome, telefone).


**Navegação Principal (ShellRoute com Bottom Navigation):**
*   **Início (`HomePage`):** Tela principal com saudação, busca rápida, categorias populares e itens próximos.
*   **Buscar (`BuscarPage`):** Busca avançada de itens com filtros por categoria, distância, preço, avaliação e ordenação.
**Favoritos (`FavoritosPage`):** Lista de itens favoritados pelo usuário, com persistência no Firebase, filtros e ordenação.
*   **Perfil (`PerfilPage`):** Perfil do usuário logado com suas informações, estatísticas (baseadas nos dados do usuário), e opções de configuração e edição de perfil.


**Gerenciamento de Itens (`itens`):**
*   **Anunciar Item (`AnunciarItemPage`):** Formulário multi-etapas para cadastrar novos itens para aluguel, incluindo informações básicas, categoria, fotos e preços.
*   **Detalhes do Item (`DetalhesItemPage`):** Visualização completa dos detalhes de um item, incluindo fotos, descrição, preços, informações do proprietário, regras, localização (mockada) e opção de alugar.


**Interação Social e Comunicação (`perfil`, `chat`, `avaliacoes`):**
*   **Perfil Público (`PerfilPublicoPage`):** Visualização do perfil de outros usuários, com suas estatísticas, avaliações recebidas e itens anunciados.
*   **Chat (`ListaChatsPage`, `ChatPage`):** Sistema de chat para comunicação entre usuários, com persistência de mensagens no Firebase. Permite iniciar chat a partir da página de detalhes do item.
*   **Avaliações (`AvaliacaoPage`):** Permite que usuários avaliem outros usuários após um aluguel, com persistência no Firebase.


**Configurações:**
*   **Configurações (`ConfiguracoesPage`):** Opções para alterar tema (Claro, Escuro, Sistema) e idioma (Português, Inglês), além de placeholders para outras configurações.

**Aluguéis (`alugueis`):**
*   **Solicitar Aluguel (`SolicitarAluguelPage`):** Interface para o usuário selecionar datas e iniciar o processo de solicitação de aluguel de um item.
*   **Aceite de Contrato (`AceiteContratoPage`):** Tela para visualização e aceite de um contrato digital gerado dinamicamente (conteúdo HTML).
*   **Caução (`CaucaoPage`):** Tela para simulação do processamento de caução de segurança para aluguéis.
*   **Status do Aluguel (`StatusAluguelPage`):** Acompanhamento do status de um aluguel, com contador de tempo, verificação de fotos (upload simulado) e opções de denúncia.
*   **Solicitações de Aluguel (`SolicitacoesAluguelPage`):** Permite ao locador visualizar e gerenciar (aprovar/recusar) as solicitações de aluguel recebidas.
*   **Meus Aluguéis (`MeusAlugueisPage`):** Lista os aluguéis do usuário (como locador e locatário).

**Segurança (componentes e lógica distribuída em `seguranca` e `alugueis`):**
*   **Verificação de Fotos (`UploadFotosVerificacao`):** Componente para upload de fotos do item antes e depois do aluguel.
*   **Denúncias:** Lógica para registrar denúncias relacionadas a aluguéis.
*   **Multa por Atraso:** Cálculo e aplicação de multas por atraso na devolução.

**Entregas (`entregas` - Funcionalidades em desenvolvimento/mockadas):**
*   **Nova Entrega (`NovaEntregaPage`):** Formulário multi-etapas para solicitar uma nova entrega.
*   **Acompanhar Entrega (`AcompanharEntregaPage`):** Tela para acompanhar o status de uma entrega (atualmente com dados mockados e mapa placeholder).

## 🛠️ Tecnologias Utilizadas

*   **Flutter:** SDK para desenvolvimento de interfaces de usuário nativas multiplataforma.
*   **Dart:** Linguagem de programação utilizada pelo Flutter.
*   **Firebase:** Plataforma BaaS (Backend as a Service) para:
    *   **FirebaseAuth:** Autenticação de usuários.
    *   **Cloud Firestore:** Banco de dados NoSQL para armazenamento de dados (usuários, itens, etc.).
    *   **Firebase Storage:** Para armazenamento de fotos de itens, perfis e evidências.
*   **Riverpod:** Solução robusta e flexível para gerenciamento de estado.
*   **GoRouter:** Pacote para roteamento declarativo e navegação.
*   **Validatorless:** Biblioteca para simplificar a validação de formulários.
*   **Shared Preferences:** Para persistência local de configurações simples (tema, idioma).
*   **Flutter HTML:** Para renderizar o conteúdo HTML dos contratos.
*   **Image Picker:** Para seleção de fotos da galeria ou câmera.

## 🏗️ Estrutura do Projeto

O projeto segue uma arquitetura orientada a features, com uma clara separação de responsabilidades:

*   `lib/features/`: Contém os módulos de cada funcionalidade (ex: `autenticacao`, `itens`, `chat`).
    *   `data/`: Modelos de dados, repositórios (implementações).
    *   `domain/`: Entidades, repositórios (abstrações), casos de uso.
    *   `presentation/`: Widgets (páginas, componentes), providers/controllers de UI.
*   `lib/core/`: Componentes e configurações compartilhadas entre as features.
    *   `config/`: Configurações de rotas, Firebase.
    *   `constants/`: Constantes da aplicação (ex: nomes de rotas).
    *   `errors/`: Exceções e utilitários de erro.
    *   `guards/`: Guards de rota (ex: `AuthGuard`).
    *   `theme/`: Definição dos temas da aplicação.
    *   `utils/`: Utilitários gerais (ex: `SnackBarUtils`).
    *   `l10n/`: Arquivos de localização (internacionalização).

## 🚀 Como Executar

1.  **Clone o repositório:**
    ```bash
    git clone https://SEU_REPOSITORIO_AQUI.git
    cd coisarapida
    ```
2.  **Configure o Firebase:**
    *   Crie um projeto no Firebase Console.
    *   Adicione um app Android e/ou iOS ao seu projeto Firebase.
    *   Siga as instruções para adicionar os arquivos de configuração (`google-services.json` para Android, `GoogleService-Info.plist` para iOS) nas pastas corretas do seu projeto Flutter.
    *   Ative os serviços do Firebase que serão utilizados (Authentication, Firestore, Storage).
    *   Configure as regras de segurança do Firestore e Storage conforme necessário.
3.  **Instale as dependências:**
    ```bash
    flutter pub get
    ```
4.  **Execute o aplicativo:**
    ```bash
    flutter run
    ```

## 📝 Status do Projeto

O projeto está **em desenvolvimento ativo**. Funcionalidades como autenticação, navegação, gerenciamento de itens, perfil, favoritos e chat (com persistência) estão bem implementadas. O fluxo de aluguel, incluindo solicitação, aceite de contrato e gerenciamento de solicitações, está funcional. Funcionalidades de segurança como denúncias e o fluxo de caução estão parcialmente implementadas ou simuladas. O módulo de entregas está em estágio inicial, utilizando dados mockados para demonstração da interface.


## 🔮 Próximos Passos (Sugestões)

*   Implementação completa da lógica de negócios para chat, aluguéis e entregas.
*   Integração real com gateways de pagamento para caução e aluguéis.
*   Desenvolvimento de mapa em tempo real para acompanhamento de entregas.
*   Implementação de notificações push.
*   Adição de testes unitários, de widget e de integração.
*   Refinamento da UI/UX.
*   Internacionalização completa das strings da UI.

---

Sinta-se à vontade para adaptar e expandir este README conforme o projeto evolui!
