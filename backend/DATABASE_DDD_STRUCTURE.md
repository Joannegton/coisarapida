# Estrutura de Banco de Dados - DDD com TypeORM

## 📋 Visão Geral

Este banco de dados foi modelado seguindo princípios de **Domain-Driven Design (DDD)** e otimizado para uso com **TypeORM** e **NestJS**.

## 🏗️ Agregados (Root Aggregates)

Agregados são clusters de objetos de domínio que são tratados como uma unidade coesa. Cada agregado tem uma raiz (root) que é o único ponto de acesso externo.

### 1. **USUÁRIO** (`usuarios`)
**Responsabilidades:**
- Gerenciar dados pessoais e de autenticação
- Controlar verificações (email, telefone, residência)
- Manter reputação e estatísticas
- Status de conta (ativo, bloqueado, verificado)

**Entidades Relacionadas:**
- `verificacoes_telefone`
- `verificacoes_residencia`

### 2. **ITEM** (`itens`)
**Responsabilidades:**
- Gerenciar anúncios de itens para aluguel/venda
- Controlar disponibilidade e status
- Manter preços e configurações
- Estatísticas de visualizações e avaliações

**Entidades Relacionadas:**
- `disponibilidades` (calendário de bloqueios)
- `favoritos`

### 3. **ALUGUEL** (`alugueis`)
**Responsabilidades:**
- Orquestrar todo o ciclo de vida de um aluguel
- Gerenciar status e transições
- Controlar caução e pagamentos
- Manter histórico de mudanças

**Entidades Relacionadas:**
- `contratos`
- `verificacoes_fotos`
- `problemas`
- `denuncias`
- `multas`
- `pagamentos`

### 4. **CONVERSA** (`conversas`)
**Responsabilidades:**
- Gerenciar comunicação entre usuários
- Manter contexto do item de interesse
- Controlar mensagens não lidas

**Entidades Relacionadas:**
- `mensagens`

## 🔗 Value Objects

Value Objects são objetos imutáveis definidos apenas por seus atributos.

### **ENDEREÇO** (`enderecos`)
- Usado por: `usuarios`, `itens`
- Compartilhado entre múltiplas entidades
- Inclui geolocalização (PostGIS)

## 📊 Entidades de Domínio

### Verificação e Compliance
- `verificacoes_telefone` - Validação de telefone via SMS
- `verificacoes_residencia` - Validação de comprovante de residência
- `verificacoes_fotos` - Fotos antes/depois do aluguel

### Transações e Financeiro
- `pagamentos` - Registro de todas transações
- `multas` - Multas por atraso ou dano
- `contratos` - Contratos digitais assinados

### Relacionamento e Social
- `avaliacoes` - Reviews de usuários e itens
- `mensagens` - Mensagens dentro de conversas
- `favoritos` - Itens favoritos dos usuários

### Moderação e Suporte
- `denuncias` - Denúncias entre usuários
- `problemas` - Problemas reportados em alugueis
- `notificacoes` - Sistema de notificações

### Sistema
- `audit_logs` - Auditoria de todas ações
- `disponibilidades` - Calendário de disponibilidade

## 🎯 Princípios Aplicados

### 1. **Separação de Agregados**
Cada agregado é independente e mantém sua própria consistência interna. Mudanças entre agregados são feitas via eventos de domínio (implementar no NestJS).

### 2. **Desnormalização Estratégica**
Dados frequentemente consultados são desnormalizados para performance:
- Nome e foto de usuários em várias tabelas
- Estatísticas (total_alugueis, reputacao, etc)
- Dados de snapshot em alugueis

### 3. **Soft Delete**
Tabelas principais usam `deleted_at` para:
- Manter histórico
- Permitir auditoria
- Facilitar recuperação de dados

### 4. **Enums Tipados**
PostgreSQL enums garantem consistência:
```sql
CREATE TYPE aluguel_status_enum AS ENUM (
    'pendente', 'aprovado', 'pago', 'ativo', ...
);
```

### 5. **Constraints de Integridade**
- Check constraints para validações de negócio
- Foreign keys com ações apropriadas
- Unique indexes para garantir unicidade

### 6. **JSONB para Flexibilidade**
Usado para dados semi-estruturados:
- `fotos` em itens (array de objetos)
- `evidencias` em denúncias
- `metadata` em mensagens
- `dados` em notificações

## 📐 Padrões TypeORM

### Entidades Base
Todas entidades devem estender uma classe base:

```typescript
@Entity()
export abstract class BaseEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  @DeleteDateColumn({ name: 'deleted_at' })
  deletedAt?: Date;
}
```

### Enums
Mapeamento de enums PostgreSQL:

```typescript
export enum AluguelStatus {
  PENDENTE = 'pendente',
  APROVADO = 'aprovado',
  PAGO = 'pago',
  ATIVO = 'ativo',
  // ...
}

@Entity('alugueis')
export class Aluguel extends BaseEntity {
  @Column({
    type: 'enum',
    enum: AluguelStatus,
    default: AluguelStatus.PENDENTE
  })
  status: AluguelStatus;
}
```

### Relacionamentos
Sempre especificar a estratégia de loading:

```typescript
@Entity('alugueis')
export class Aluguel extends BaseEntity {
  @ManyToOne(() => Item, { eager: false })
  @JoinColumn({ name: 'item_id' })
  item: Item;

  @OneToMany(() => Problema, problema => problema.aluguel, { lazy: true })
  problemas: Promise<Problema[]>;
}
```

## 🔍 Índices Importantes

### Índices de Performance
```sql
-- Buscas geoespaciais
CREATE INDEX idx_enderecos_geopoint ON enderecos USING GIST(geopoint);

-- Filtros comuns
CREATE INDEX idx_itens_categoria ON itens(categoria) 
  WHERE deleted_at IS NULL AND status = 'ativo';

-- Ordenação
CREATE INDEX idx_itens_avaliacao ON itens(avaliacao_media DESC) 
  WHERE deleted_at IS NULL AND status = 'ativo';
```

### Índices Parciais
Usados para otimizar queries específicas:
```sql
CREATE INDEX idx_alugueis_ativo ON alugueis(item_id, status) 
  WHERE deleted_at IS NULL AND status = 'ativo';
```

## 🔐 Segurança

### 1. Dados Sensíveis
- CPF e telefone únicos mas opcionais
- Senha NUNCA armazenada no banco (usar Firebase Auth)
- Códigos de verificação armazenados com hash

### 2. Auditoria
Todas ações importantes são logadas em `audit_logs`:
- Criação/edição/exclusão de registros
- Mudanças de status
- Ações administrativas

### 3. IP e User Agent
Rastreamento de origem para segurança:
- `contratos.ip_aceite_*`
- `audit_logs.ip_address`

## 📊 Views Materializadas

Para relatórios e dashboards, considere criar views materializadas:

```sql
CREATE MATERIALIZED VIEW mv_estatisticas_itens AS
SELECT 
    i.categoria,
    COUNT(*) as total_itens,
    AVG(i.avaliacao_media) as avaliacao_media,
    AVG(i.preco_por_dia) as preco_medio
FROM itens i
WHERE i.deleted_at IS NULL AND i.status = 'ativo'
GROUP BY i.categoria;

CREATE UNIQUE INDEX ON mv_estatisticas_itens(categoria);
```

## 🚀 Migrations com TypeORM

### Estrutura Recomendada
```
src/
├── database/
│   ├── migrations/
│   │   ├── 1697000000001-CreateUsuarios.ts
│   │   ├── 1697000000002-CreateItens.ts
│   │   ├── 1697000000003-CreateAlugueis.ts
│   │   └── ...
│   ├── seeds/
│   │   ├── 1-usuarios.seed.ts
│   │   └── 2-categorias.seed.ts
│   └── entities/
│       ├── usuario.entity.ts
│       ├── item.entity.ts
│       └── ...
```

### Gerar Migration
```bash
npm run migration:generate -- -n CreateUsuarios
npm run migration:run
```

## 📦 Repositórios (Repository Pattern)

Cada agregado deve ter seu repositório:

```typescript
@Injectable()
export class AluguelRepository {
  constructor(
    @InjectRepository(Aluguel)
    private readonly repository: Repository<Aluguel>,
  ) {}

  async findByIdWithRelations(id: string): Promise<Aluguel> {
    return this.repository.findOne({
      where: { id },
      relations: ['item', 'locador', 'locatario', 'contrato'],
    });
  }

  async findAtivosDoUsuario(usuarioId: string): Promise<Aluguel[]> {
    return this.repository.find({
      where: [
        { locadorId: usuarioId, status: AluguelStatus.ATIVO },
        { locatarioId: usuarioId, status: AluguelStatus.ATIVO },
      ],
      order: { dataInicio: 'DESC' },
    });
  }
}
```

## 🎨 Domain Services

Para operações que envolvem múltiplos agregados:

```typescript
@Injectable()
export class AluguelService {
  constructor(
    private readonly aluguelRepo: AluguelRepository,
    private readonly itemRepo: ItemRepository,
    private readonly pagamentoService: PagamentoService,
    private readonly notificacaoService: NotificacaoService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async aprovarAluguel(aluguelId: string): Promise<Aluguel> {
    const aluguel = await this.aluguelRepo.findByIdWithRelations(aluguelId);
    
    // Validações
    if (aluguel.status !== AluguelStatus.PENDENTE) {
      throw new BadRequestException('Aluguel não está pendente');
    }

    // Mudança de estado
    aluguel.status = AluguelStatus.APROVADO;
    await this.aluguelRepo.save(aluguel);

    // Eventos de domínio
    this.eventEmitter.emit('aluguel.aprovado', {
      aluguelId: aluguel.id,
      locatarioId: aluguel.locatarioId,
    });

    // Efeitos colaterais
    await this.notificacaoService.notificarAprovacaoAluguel(aluguel);

    return aluguel;
  }
}
```

## 🧪 Testes

### Factories para Testes
```typescript
export class UsuarioFactory {
  static criar(overrides?: Partial<Usuario>): Usuario {
    return {
      id: faker.datatype.uuid(),
      nome: faker.name.fullName(),
      email: faker.internet.email(),
      reputacao: 4.5,
      verificado: true,
      ...overrides,
    };
  }
}
```

### Testes de Repositório
```typescript
describe('AluguelRepository', () => {
  let repository: AluguelRepository;
  let dataSource: DataSource;

  beforeAll(async () => {
    // Setup test database
  });

  it('deve encontrar aluguéis ativos do usuário', async () => {
    const usuario = await UsuarioFactory.criar();
    const aluguel = await AluguelFactory.criar({
      locatarioId: usuario.id,
      status: AluguelStatus.ATIVO,
    });

    const result = await repository.findAtivosDoUsuario(usuario.id);

    expect(result).toHaveLength(1);
    expect(result[0].id).toBe(aluguel.id);
  });
});
```

## 📈 Performance Tips

1. **Use Select Específico**: Não carregue colunas desnecessárias
2. **Lazy Loading**: Use para relacionamentos grandes
3. **Pagination**: Sempre pagine listas
4. **Índices**: Crie índices para colunas em WHERE e ORDER BY
5. **Query Builder**: Use para queries complexas
6. **Cache**: Implemente cache para dados estáticos

## 🔄 Event Sourcing (Futuro)

Para auditoria completa, considere implementar Event Sourcing:

```typescript
@Entity('eventos_dominio')
export class EventoDominio {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  agregadoTipo: string;

  @Column('uuid')
  agregadoId: string;

  @Column()
  eventoTipo: string;

  @Column('jsonb')
  payload: any;

  @CreateDateColumn()
  ocorridoEm: Date;
}
```

## 📚 Referências

- [TypeORM Documentation](https://typeorm.io/)
- [NestJS Database](https://docs.nestjs.com/techniques/database)
- [Domain-Driven Design](https://martinfowler.com/bliki/DomainDrivenDesign.html)
- [PostgreSQL Best Practices](https://wiki.postgresql.org/wiki/Don%27t_Do_This)
