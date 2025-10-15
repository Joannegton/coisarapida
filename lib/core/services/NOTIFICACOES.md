# 📱 Sistema de Notificações Push - Coisa Rápida

## 🎯 Visão Geral

Este documento descreve a implementação completa do sistema de notificações push usando Firebase Cloud Messaging (FCM) para o aplicativo Coisa Rápida.

## ✨ Funcionalidades

O sistema de notificações envia notificações automáticas em tempo real para os usuários nos seguintes eventos:

### 🔔 Notificações Implementadas

1. **Nova Solicitação** - Quando um locatário solicita alugar um item
2. **Solicitação Aprovada** - Quando o locador aprova uma solicitação
3. **Solicitação Recusada** - Quando o locador recusa uma solicitação
4. **Pagamento Pendente** - Lembrete de pagamento
5. **Pagamento Confirmado** - Quando o pagamento é processado
6. **Aluguel Iniciado** - Quando o aluguel é confirmado
7. **Lembrete de Devolução** - Próximo da data de devolução
8. **Devolução Solicitada** - Quando o locatário solicita devolução
9. **Devolução Aprovada** - Quando o locador aprova a devolução
10. **Avaliação Pendente** - Lembrete para avaliar após conclusão

## 📋 Pré-requisitos

### Para Android

1. Arquivo `google-services.json` configurado no projeto
2. Permissões no `AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/> <!-- Android 13+ -->
    
    <application>
        <!-- Configuração do ícone de notificação -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@mipmap/ic_launcher" />
        
        <!-- Cor padrão da notificação -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_color"
            android:resource="@color/notification_color" />
            
        <!-- Canal de notificação -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="aluguel_notifications" />
    </application>
</manifest>
```

### Para iOS

1. Configurar Push Notifications no Xcode
2. Arquivo `GoogleService-Info.plist` configurado
3. Certificado APNs configurado no Firebase Console

## 🚀 Configuração

### 1. Dependências

As seguintes dependências já foram adicionadas no `pubspec.yaml`:

```yaml
dependencies:
  firebase_messaging: ^16.0.0
  flutter_local_notifications: ^18.0.1
```

### 2. Estrutura de Arquivos

```
lib/
├── core/
│   ├── services/
│   │   ├── notification_service.dart       # Serviço principal de notificações
│   │   └── notification_manager.dart       # Gerenciador de tipos de notificações
│   └── providers/
│       └── notification_provider.dart      # Providers Riverpod
│
backend/
└── functions/
    ├── index.js                            # Exportação das functions
    └── notifications.js                    # Cloud Functions de notificações
```

### 3. Cloud Functions

As Cloud Functions precisam ser implantadas no Firebase:

```bash
cd backend/functions
npm install
firebase deploy --only functions
```

#### Funções Disponíveis:

1. **enviarNotificacao** - Envia notificação para um dispositivo
2. **enviarNotificacaoMultipla** - Envia para múltiplos dispositivos
3. **notificarNovaSolicitacao** - Trigger automático ao criar solicitação
4. **notificarAtualizacaoSolicitacao** - Trigger automático ao atualizar status

### 4. Firestore Rules

Adicione regras para permitir que as Cloud Functions atualizem os tokens FCM:

```javascript
match /usuarios/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
  
  // Permitir que functions atualizem o FCM token
  allow update: if request.auth != null && 
                   request.resource.data.diff(resource.data).affectedKeys()
                   .hasOnly(['fcmToken', 'fcmTokenUpdatedAt']);
}
```

## 💻 Uso no Código

### Inicialização

O serviço é inicializado automaticamente no login:

```dart
// Em auth_provider.dart
Future<void> loginComEmail({
  required String email,
  required String senha,
}) async {
  await _authRepository.loginComEmail(email: email, senha: senha);
  
  // Inicializar notificações
  await _setupNotifications();
}
```

### Enviar Notificação Manual

```dart
// Obter o NotificationManager
final notificationManager = ref.read(notificationManagerProvider);

// Enviar notificação
await notificationManager.notificarNovaSolicitacao(
  locadorId: 'USER_ID',
  locatarioNome: 'João Silva',
  itemNome: 'Furadeira Elétrica',
  aluguelId: 'ALUGUEL_ID',
);
```

### Notificações Automáticas

As notificações são enviadas automaticamente quando:

1. **Uma solicitação é criada** (em `AluguelController.submeterAluguelCompleto`)
2. **Uma solicitação é aprovada** (em `SolicitacaoHelpers.aprovarSolicitacao`)
3. **Uma solicitação é recusada** (em `SolicitacaoHelpers.recusarSolicitacao`)

## 🧪 Testando

### Teste Local

1. Execute o app em dois dispositivos/emuladores
2. Faça login como locador em um e locatário em outro
3. Crie uma solicitação no dispositivo do locatário
4. A notificação deve aparecer instantaneamente no dispositivo do locador

### Teste com Cloud Functions

Após fazer deploy das functions, teste com:

```bash
# Ver logs em tempo real
firebase functions:log --only notificarNovaSolicitacao
```

### Teste Manual de Token

```dart
// Obter o token FCM atual
final notificationService = ref.read(notificationServiceProvider);
final token = notificationService.fcmToken;
print('FCM Token: $token');
```

## 📊 Monitoramento

### Firebase Console

1. Acesse Firebase Console > Cloud Messaging
2. Visualize estatísticas de entrega
3. Monitore tokens inválidos

### Logs

Os logs são exibidos com prefixos:
- ✅ Sucesso
- ⚠️ Aviso
- ❌ Erro
- 📨 Mensagem recebida
- 🔔 Notificação clicada

## 🔧 Troubleshooting

### Notificações não aparecem no Android

1. Verifique se as permissões estão concedidas
2. Verifique o canal de notificação
3. Certifique-se de que o app não está em modo economia de bateria

### Notificações não aparecem no iOS

1. Verifique se as permissões foram solicitadas
2. Certifique-se de que o certificado APNs está configurado
3. Teste em dispositivo físico (não funciona no simulador)

### Token não é salvo

1. Verifique se o usuário está autenticado
2. Verifique as regras do Firestore
3. Confira os logs para erros

### Cloud Functions não são executadas

1. Verifique se o plano do Firebase permite Cloud Functions
2. Confira se as functions foram implantadas corretamente
3. Verifique os logs no Firebase Console

## 🎨 Personalização

### Alterar Ícone da Notificação

Substitua o ícone em:
```
android/app/src/main/res/mipmap-*/ic_launcher.png
```

### Alterar Som da Notificação

Adicione arquivo de som em:
```
android/app/src/main/res/raw/notification_sound.mp3
```

E configure em `notification_service.dart`:
```dart
sound: 'notification_sound',
```

### Adicionar Novo Tipo de Notificação

1. Adicione enum em `notification_manager.dart`:
```dart
enum TipoNotificacao {
  // ... existentes
  meuNovoTipo('meu_novo_tipo', 'Minha Notificação'),
}
```

2. Crie o método:
```dart
Future<void> notificarMeuNovoEvento({
  required String usuarioId,
  required String mensagem,
}) async {
  await _enviarNotificacao(
    destinatarioId: usuarioId,
    tipo: TipoNotificacao.meuNovoTipo,
    titulo: 'Título',
    mensagem: mensagem,
    dados: {'tipo': 'meu_novo_tipo'},
  );
}
```

## 📱 Comportamento por Plataforma

### Android
- Notificações aparecem na gaveta de notificações
- Som e vibração configuráveis
- Suporta canais de notificação (Android 8+)
- Requer permissão em Android 13+

### iOS
- Notificações aparecem no centro de notificações
- Requer permissão explícita do usuário
- Badge count automático
- Sons personalizáveis

## 🔒 Segurança

- Tokens FCM são armazenados de forma segura no Firestore
- Cloud Functions validam autenticação antes de enviar
- Tokens inválidos são automaticamente removidos
- Dados sensíveis não são incluídos nas notificações

## 📈 Próximos Passos

- [ ] Adicionar notificações programadas (lembretes)
- [ ] Implementar deep linking completo
- [ ] Adicionar configurações de notificação para usuários
- [ ] Implementar notificações silenciosas para atualizações de dados
- [ ] Adicionar analytics de notificações

## 🤝 Contribuindo

Ao adicionar novas notificações:

1. Adicione o tipo em `TipoNotificacao`
2. Crie o método em `NotificationManager`
3. Chame o método no lugar apropriado do código
4. Adicione testes
5. Atualize esta documentação

## 📞 Suporte

Para problemas ou dúvidas:
- Verifique os logs do aplicativo
- Consulte a documentação do Firebase
- Revise este documento

---

**Última atualização:** Outubro 2025
**Versão:** 1.0.0
