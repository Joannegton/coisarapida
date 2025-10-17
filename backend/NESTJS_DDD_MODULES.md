# 📁 Estrutura de Módulos NestJS - DDD

## 🏗️ Arquitetura Geral

```
src/
├── core/                          # Núcleo da aplicação
│   ├── database/                  # Configurações de banco
│   ├── auth/                      # Autenticação/Autorização
│   ├── notifications/             # Sistema de notificações
│   └── shared/                    # Utilitários compartilhados
├── domains/                       # Domínios de negócio
│   ├── usuario/                   # 👤 Domínio do Usuário
│   ├── item/                      # 📦 Domínio do Item
│   ├── aluguel/                   # 🤝 Domínio do Aluguel
│   ├── conversa/                  # 💬 Domínio da Conversa
│   ├── pagamento/                 # 💰 Domínio do Pagamento
│   └── moderacao/                 # ⚖️ Domínio de Moderação
├── infrastructure/                # Camada de infraestrutura
│   ├── external/                  # Integrações externas
│   └── persistence/               # Repositórios e migrations
└── presentation/                  # Camada de apresentação
    ├── controllers/               # Controllers REST
    ├── dto/                       # Data Transfer Objects
    └── guards/                    # Guards de segurança
```

---

## 👤 **Módulo: USUARIO** (`domains/usuario/`)

**Agregado Raiz:** `usuarios`

### Entidades Relacionadas:
- `verificacoes_telefone`
- `verificacoes_residencia`

### Estrutura:
```
domains/usuario/
├── entities/
│   ├── usuario.entity.ts
│   ├── verificacao-telefone.entity.ts
│   └── verificacao-residencia.entity.ts
├── repositories/
│   ├── usuario.repository.ts
│   ├── verificacao-telefone.repository.ts
│   └── verificacao-residencia.repository.ts
├── services/
│   ├── usuario.service.ts
│   ├── verificacao.service.ts
│   └── reputacao.service.ts
├── dto/
│   ├── create-usuario.dto.ts
│   ├── update-usuario.dto.ts
│   └── verificacao.dto.ts
├── controllers/
│   └── usuario.controller.ts
├── guards/
│   └── usuario-owner.guard.ts
└── usuario.module.ts
```

### Responsabilidades:
- ✅ Gerenciamento de perfil do usuário
- ✅ Verificações (telefone, residência)
- ✅ Cálculo de reputação
- ✅ Controle de status (ativo/bloqueado)

---

## 📦 **Módulo: ITEM** (`domains/item/`)

**Agregado Raiz:** `itens`

### Entidades Relacionadas:
- `disponibilidades`
- `favoritos`

### Estrutura:
```
domains/item/
├── entities/
│   ├── item.entity.ts
│   ├── disponibilidade.entity.ts
│   └── favorito.entity.ts
├── repositories/
│   ├── item.repository.ts
│   ├── disponibilidade.repository.ts
│   └── favorito.repository.ts
├── services/
│   ├── item.service.ts
│   ├── disponibilidade.service.ts
│   ├── favorito.service.ts
│   └── busca.service.ts
├── dto/
│   ├── create-item.dto.ts
│   ├── update-item.dto.ts
│   └── busca-item.dto.ts
├── controllers/
│   └── item.controller.ts
└── item.module.ts
```

### Responsabilidades:
- ✅ CRUD de itens
- ✅ Controle de disponibilidade/calendário
- ✅ Sistema de favoritos
- ✅ Busca e filtros
- ✅ Estatísticas de visualização

---

## 🤝 **Módulo: ALUGUEL** (`domains/aluguel/`)

**Agregado Raiz:** `alugueis`

### Entidades Relacionadas:
- `contratos`
- `verificacoes_fotos`
- `problemas`
- `denuncias`
- `multas`

### Estrutura:
```
domains/aluguel/
├── entities/
│   ├── aluguel.entity.ts
│   ├── contrato.entity.ts
│   ├── verificacao-foto.entity.ts
│   ├── problema.entity.ts
│   ├── denuncia.entity.ts
│   └── multa.entity.ts
├── repositories/
│   ├── aluguel.repository.ts
│   ├── contrato.repository.ts
│   ├── verificacao-foto.repository.ts
│   ├── problema.repository.ts
│   ├── denuncia.repository.ts
│   └── multa.repository.ts
├── services/
│   ├── aluguel.service.ts
│   ├── contrato.service.ts
│   ├── verificacao-foto.service.ts
│   ├── problema.service.ts
│   ├── denuncia.service.ts
│   ├── multa.service.ts
│   └── workflow-aluguel.service.ts
├── dto/
│   ├── create-aluguel.dto.ts
│   ├── update-aluguel.dto.ts
│   └── contrato.dto.ts
├── controllers/
│   └── aluguel.controller.ts
├── guards/
│   └── aluguel-participante.guard.ts
└── aluguel.module.ts
```

### Responsabilidades:
- ✅ Ciclo de vida completo do aluguel
- ✅ Gestão de contratos
- ✅ Verificações fotográficas
- ✅ Relatório de problemas
- ✅ Sistema de denúncias
- ✅ Aplicação de multas
- ✅ Workflow de estados

---

## 💬 **Módulo: CONVERSA** (`domains/conversa/`)

**Agregado Raiz:** `conversas`

### Entidades Relacionadas:
- `mensagens`

### Estrutura:
```
domains/conversa/
├── entities/
│   ├── conversa.entity.ts
│   └── mensagem.entity.ts
├── repositories/
│   ├── conversa.repository.ts
│   └── mensagem.repository.ts
├── services/
│   ├── conversa.service.ts
│   ├── mensagem.service.ts
│   └── notificacao-mensagem.service.ts
├── dto/
│   ├── create-mensagem.dto.ts
│   └── conversa.dto.ts
├── controllers/
│   └── conversa.controller.ts
├── gateways/
│   └── chat.gateway.ts          # WebSocket para chat em tempo real
└── conversa.module.ts
```

### Responsabilidades:
- ✅ Sistema de chat entre usuários
- ✅ Mensagens em tempo real (WebSocket)
- ✅ Controle de mensagens não lidas
- ✅ Arquivamento de conversas

---

## 💰 **Módulo: PAGAMENTO** (`domains/pagamento/`)

**Agregado Raiz:** `pagamentos`

### Estrutura:
```
domains/pagamento/
├── entities/
│   └── pagamento.entity.ts
├── repositories/
│   └── pagamento.repository.ts
├── services/
│   ├── pagamento.service.ts
│   ├── gateway.service.ts        # Integração com gateways
│   ├── reembolso.service.ts
│   └── webhook.service.ts
├── dto/
│   ├── create-pagamento.dto.ts
│   └── webhook.dto.ts
├── controllers/
│   └── pagamento.controller.ts
├── strategies/
│   ├── pix.strategy.ts
│   ├── cartao.strategy.ts
│   └── boleto.strategy.ts
└── pagamento.module.ts
```

### Responsabilidades:
- ✅ Processamento de pagamentos
- ✅ Integração com gateways (Mercado Pago, etc.)
- ✅ Reembolsos
- ✅ Webhooks de confirmação
- ✅ Múltiplos métodos de pagamento

---

## ⚖️ **Módulo: MODERACAO** (`domains/moderacao/`)

**Entidades Relacionadas:**
- `avaliacoes`
- `audit_logs`

### Estrutura:
```
domains/moderacao/
├── entities/
│   ├── avaliacao.entity.ts
│   └── audit-log.entity.ts
├── repositories/
│   ├── avaliacao.repository.ts
│   └── audit-log.repository.ts
├── services/
│   ├── moderacao.service.ts
│   ├── avaliacao.service.ts
│   ├── audit.service.ts
│   └── relatorio.service.ts
├── dto/
│   ├── create-avaliacao.dto.ts
│   └── moderacao.dto.ts
├── controllers/
│   └── moderacao.controller.ts
├── guards/
│   └── admin-only.guard.ts
└── moderacao.module.ts
```

### Responsabilidades:
- ✅ Moderação de avaliações
- ✅ Sistema de auditoria
- ✅ Relatórios administrativos
- ✅ Controle de qualidade

---

## 🔔 **Módulo: NOTIFICATIONS** (`core/notifications/`)

**Entidade:** `notificacoes`

### Estrutura:
```
core/notifications/
├── entities/
│   └── notificacao.entity.ts
├── repositories/
│   └── notificacao.repository.ts
├── services/
│   ├── notificacao.service.ts
│   ├── push.service.ts
│   ├── email.service.ts
│   └── sms.service.ts
├── dto/
│   └── notificacao.dto.ts
├── controllers/
│   └── notificacao.controller.ts
├── templates/
│   ├── email/
│   └── push/
└── notifications.module.ts
```

### Responsabilidades:
- ✅ Envio de notificações push
- ✅ Sistema de email
- ✅ SMS para verificações
- ✅ Templates de mensagens

---

## 🔧 **Módulo: SHARED** (`core/shared/`)

### Estrutura:
```
core/shared/
├── entities/
│   └── endereco.entity.ts        # Value Object compartilhado
├── decorators/
│   ├── user.decorator.ts
│   └── roles.decorator.ts
├── guards/
│   ├── jwt.guard.ts
│   └── roles.guard.ts
├── interceptors/
│   ├── logging.interceptor.ts
│   └── transform.interceptor.ts
├── filters/
│   └── exception.filter.ts
├── utils/
│   ├── date.util.ts
│   ├── validation.util.ts
│   └── crypto.util.ts
└── shared.module.ts
```

### Responsabilidades:
- ✅ Utilitários compartilhados
- ✅ Guards e decorators globais
- ✅ Interceptors e filters
- ✅ Value Objects (Endereço)

---

## 📊 **Módulo: INFRASTRUCTURE** (`infrastructure/`)

### Estrutura:
```
infrastructure/
├── database/
│   ├── migrations/
│   ├── seeds/
│   └── config/
├── external/
│   ├── firebase/
│   ├── mercadopago/
│   ├── twilio/
│   └── maps/
├── cache/
│   └── redis/
└── storage/
    ├── cloud-storage.service.ts
    └── local-storage.service.ts
```

---

## 🎯 **Módulo Principal** (`app.module.ts`)

```typescript
@Module({
  imports: [
    // Core
    SharedModule,
    DatabaseModule,
    AuthModule,
    NotificationsModule,

    // Domains
    UsuarioModule,
    ItemModule,
    AluguelModule,
    ConversaModule,
    PagamentoModule,
    ModeracaoModule,

    // Infrastructure
    InfrastructureModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
```

---

## 🔄 **Fluxo de Dependências (Clean Architecture)**

```
┌─────────────────────────────────────┐
│         PRESENTATION LAYER          │  ← Controllers, DTOs
├─────────────────────────────────────┤
│         DOMAIN LAYER                │  ← Entities, Services, Repositories
├─────────────────────────────────────┤
│       INFRASTRUCTURE LAYER          │  ← External APIs, Database
└─────────────────────────────────────┘
```

### Regras de Dependência:
- ✅ **Domain** não conhece Infrastructure
- ✅ **Presentation** conhece Domain
- ✅ **Infrastructure** implementa interfaces do Domain
- ✅ Dependências sempre apontam para dentro

---

## 📋 **Exemplo: Serviço de Aluguel**

```typescript
@Injectable()
export class AluguelService {
  constructor(
    private readonly aluguelRepo: IAluguelRepository,
    private readonly itemRepo: IItemRepository,
    private readonly usuarioRepo: IUsuarioRepository,
    private readonly pagamentoService: IPagamentoService,
    private readonly notificacaoService: INotificacaoService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async solicitarAluguel(dto: CreateAluguelDto): Promise<Aluguel> {
    // 1. Validações de negócio
    const item = await this.itemRepo.findById(dto.itemId);
    const locatario = await this.usuarioRepo.findById(dto.locatarioId);

    // 2. Regras de negócio
    this.validarDisponibilidade(item, dto.dataInicio, dto.dataFim);
    this.validarReputacao(locatario);

    // 3. Criação do aluguel
    const aluguel = await this.aluguelRepo.create({
      ...dto,
      status: AluguelStatus.PENDENTE,
    });

    // 4. Efeitos colaterais
    await this.notificacaoService.notificarLocador(aluguel);

    // 5. Evento de domínio
    this.eventEmitter.emit('aluguel.solicitado', aluguel);

    return aluguel;
  }
}
```

---

## 🧪 **Testes por Módulo**

```
domains/usuario/
├── usuario.service.spec.ts
├── usuario.repository.spec.ts
├── usuario.controller.spec.ts
└── e2e/
    └── usuario.e2e-spec.ts
```

---

## 🚀 **Próximos Passos**

1. **Criar estrutura de pastas** conforme acima
2. **Implementar entidades TypeORM** para cada tabela
3. **Criar interfaces de repositório** no domínio
4. **Implementar serviços de domínio** com regras de negócio
5. **Criar controllers** na camada de apresentação
6. **Configurar injeção de dependência** entre módulos
7. **Implementar testes unitários** e de integração
8. **Configurar migrations** e seeds

Esta estrutura garante:
- ✅ Separação clara de responsabilidades
- ✅ Facilidade de manutenção e evolução
- ✅ Testabilidade independente
- ✅ Reutilização de código
- ✅ Escalabilidade horizontal</content>
<parameter name="filePath">d:\Users\Bolacha\cursos_geral\flutter\coisarapida\backend\NESTJS_DDD_MODULES.md
