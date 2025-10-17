-- =============================================
-- Schema PostgreSQL - DDD com TypeORM/NestJS
-- =============================================
-- Princípios aplicados:
-- 1. Domain-Driven Design (DDD): Separação clara de agregados e entidades
-- 2. TypeORM: Compatível com decorators e migrations
-- 3. Normalização: 3FN com desnormalização estratégica para performance
-- 4. Soft Delete: Uso de deleted_at para auditoria
-- 5. Timestamps: created_at e updated_at automáticos
-- 6. UUIDs: Identificadores distribuídos
-- 7. Constraints: Integridade referencial e validações
-- 8. Índices: Otimização de queries comuns
-- =============================================

-- Extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================
-- AGREGADO: ENDEREÇO (Value Object compartilhado)
-- =============================================
CREATE TABLE enderecos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Dados do endereço
    cep VARCHAR(10) NOT NULL,
    rua VARCHAR(255) NOT NULL,
    numero VARCHAR(20) NOT NULL,
    complemento VARCHAR(255),
    bairro VARCHAR(100) NOT NULL,
    cidade VARCHAR(100) NOT NULL,
    estado CHAR(2) NOT NULL,
    pais VARCHAR(100) DEFAULT 'Brasil',
    
    -- Geolocalização
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    geopoint GEOGRAPHY(POINT, 4326), -- PostGIS para queries espaciais
    
    -- Metadados
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    
    -- Constraints
    CONSTRAINT chk_estado CHECK (LENGTH(estado) = 2),
    CONSTRAINT chk_coordenadas CHECK (
        (latitude IS NULL AND longitude IS NULL) OR 
        (latitude IS NOT NULL AND longitude IS NOT NULL AND 
         latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180)
    )
);

CREATE INDEX idx_enderecos_cep ON enderecos(cep) WHERE deleted_at IS NULL;
CREATE INDEX idx_enderecos_cidade_estado ON enderecos(cidade, estado) WHERE deleted_at IS NULL;
CREATE INDEX idx_enderecos_geopoint ON enderecos USING GIST(geopoint) WHERE deleted_at IS NULL;

-- =============================================
-- AGREGADO: USUÁRIO (Root Aggregate)
-- =============================================
CREATE TABLE usuarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Dados pessoais
    nome VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    telefone VARCHAR(20),
    cpf VARCHAR(14) UNIQUE,
    foto_url VARCHAR(1024),
    
    -- Endereço (FK)
    endereco_id UUID REFERENCES enderecos(id) ON DELETE SET NULL,
    
    -- Status e verificação
    email_verificado BOOLEAN NOT NULL DEFAULT FALSE,
    telefone_verificado BOOLEAN NOT NULL DEFAULT FALSE,
    residencia_verificada BOOLEAN NOT NULL DEFAULT FALSE,
    verificado BOOLEAN NOT NULL DEFAULT FALSE, -- Todas verificações completas
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    bloqueado BOOLEAN NOT NULL DEFAULT FALSE,
    motivo_bloqueio TEXT,
    
    -- Reputação (denormalizado para performance)
    reputacao DECIMAL(3,2) NOT NULL DEFAULT 0.0,
    total_avaliacoes INTEGER NOT NULL DEFAULT 0,
    
    -- Estatísticas (denormalizado)
    total_alugueis_como_locador INTEGER NOT NULL DEFAULT 0,
    total_alugueis_como_locatario INTEGER NOT NULL DEFAULT 0,
    total_itens_cadastrados INTEGER NOT NULL DEFAULT 0,
    
    -- Metadados
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    ultimo_acesso TIMESTAMPTZ,
    
    -- Constraints
    CONSTRAINT chk_usuario_reputacao CHECK (reputacao >= 0 AND reputacao <= 5),
    CONSTRAINT chk_usuario_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$'),
    CONSTRAINT chk_usuario_cpf CHECK (cpf IS NULL OR LENGTH(cpf) = 14)
);

CREATE INDEX idx_usuarios_email ON usuarios(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_usuarios_cpf ON usuarios(cpf) WHERE deleted_at IS NULL AND cpf IS NOT NULL;
CREATE INDEX idx_usuarios_telefone ON usuarios(telefone) WHERE deleted_at IS NULL AND telefone IS NOT NULL;
CREATE INDEX idx_usuarios_verificado ON usuarios(verificado) WHERE deleted_at IS NULL;
CREATE INDEX idx_usuarios_reputacao ON usuarios(reputacao DESC) WHERE deleted_at IS NULL;

-- =============================================
-- ENTIDADE: VERIFICAÇÃO DE TELEFONE
-- =============================================
CREATE TYPE verificacao_status_enum AS ENUM ('pendente', 'enviado', 'verificado', 'expirado', 'cancelado');

CREATE TABLE verificacoes_telefone (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    
    -- Dados da verificação
    telefone VARCHAR(20) NOT NULL,
    codigo_hash VARCHAR(255), -- Hash do código para segurança
    status verificacao_status_enum NOT NULL DEFAULT 'pendente',
    
    -- Controle de tentativas
    tentativas INTEGER NOT NULL DEFAULT 0,
    max_tentativas INTEGER NOT NULL DEFAULT 3,
    
    -- Datas
    data_envio TIMESTAMPTZ,
    data_expiracao TIMESTAMPTZ,
    data_verificacao TIMESTAMPTZ,
    
    -- Metadados
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_verificacao_telefone_tentativas CHECK (tentativas <= max_tentativas)
);

CREATE INDEX idx_verificacoes_telefone_usuario ON verificacoes_telefone(usuario_id);
CREATE INDEX idx_verificacoes_telefone_status ON verificacoes_telefone(status);
CREATE INDEX idx_verificacoes_telefone_expiracao ON verificacoes_telefone(data_expiracao) WHERE status = 'enviado';

-- =============================================
-- ENTIDADE: VERIFICAÇÃO DE RESIDÊNCIA
-- =============================================
CREATE TYPE moderacao_status_enum AS ENUM ('pendente', 'em_analise', 'aprovado', 'rejeitado', 'cancelado');

CREATE TABLE verificacoes_residencia (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    endereco_id UUID REFERENCES enderecos(id) ON DELETE SET NULL,
    
    -- Comprovante
    comprovante_url VARCHAR(1024) NOT NULL,
    tipo_comprovante VARCHAR(50), -- 'conta_luz', 'conta_agua', 'contrato', etc
    
    -- Status e moderação
    status moderacao_status_enum NOT NULL DEFAULT 'pendente',
    moderador_id UUID REFERENCES usuarios(id) ON DELETE SET NULL,
    observacoes_usuario TEXT,
    observacoes_moderador TEXT,
    motivo_rejeicao TEXT,
    
    -- Datas
    data_submissao TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_inicio_analise TIMESTAMPTZ,
    data_conclusao TIMESTAMPTZ,
    
    -- Metadados
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_verificacao_residencia_conclusao CHECK (
        (status IN ('aprovado', 'rejeitado') AND data_conclusao IS NOT NULL) OR
        (status NOT IN ('aprovado', 'rejeitado') AND data_conclusao IS NULL)
    )
);

CREATE INDEX idx_verificacoes_residencia_usuario ON verificacoes_residencia(usuario_id);
CREATE INDEX idx_verificacoes_residencia_status ON verificacoes_residencia(status);
CREATE INDEX idx_verificacoes_residencia_moderador ON verificacoes_residencia(moderador_id) WHERE moderador_id IS NOT NULL;

-- =============================================
-- AGREGADO: ITEM (Root Aggregate)
-- =============================================
CREATE TYPE item_tipo_enum AS ENUM ('aluguel', 'venda', 'ambos');
CREATE TYPE item_estado_enum AS ENUM ('novo', 'seminovo', 'usado', 'necessita_reparos');
CREATE TYPE item_status_enum AS ENUM ('rascunho', 'ativo', 'inativo', 'alugado', 'vendido', 'manutencao');

CREATE TABLE itens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Dados básicos
    nome VARCHAR(255) NOT NULL,
    descricao TEXT NOT NULL,
    categoria VARCHAR(100) NOT NULL,
    subcategoria VARCHAR(100),
    
    -- Fotos (array de objetos com url e ordem)
    fotos JSONB NOT NULL DEFAULT '[]',
    foto_principal_url VARCHAR(1024),
    
    -- Preços
    preco_por_dia DECIMAL(10,2),
    preco_por_hora DECIMAL(10,2),
    preco_venda DECIMAL(10,2),
    valor_caucao DECIMAL(10,2),
    
    -- Tipo e estado
    tipo item_tipo_enum NOT NULL DEFAULT 'aluguel',
    estado item_estado_enum NOT NULL DEFAULT 'usado',
    status item_status_enum NOT NULL DEFAULT 'ativo',
    
    -- Regras e configurações
    regras_uso TEXT,
    tempo_minimo_aluguel INTEGER, -- em horas
    tempo_maximo_aluguel INTEGER, -- em horas
    aprovacao_automatica BOOLEAN NOT NULL DEFAULT TRUE,
    permite_retirada BOOLEAN NOT NULL DEFAULT TRUE,
    permite_entrega BOOLEAN NOT NULL DEFAULT FALSE,
    raio_entrega_km INTEGER,
    
    -- Proprietário (FK)
    proprietario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    
    -- Dados denormalizados do proprietário (performance)
    proprietario_nome VARCHAR(255) NOT NULL,
    proprietario_foto_url VARCHAR(1024),
    proprietario_reputacao DECIMAL(3,2) NOT NULL DEFAULT 0.0,
    
    -- Localização (FK)
    localizacao_id UUID NOT NULL REFERENCES enderecos(id) ON DELETE RESTRICT,
    
    -- Estatísticas (denormalizado)
    avaliacao_media DECIMAL(3,2) NOT NULL DEFAULT 0.0,
    total_avaliacoes INTEGER NOT NULL DEFAULT 0,
    total_alugueis INTEGER NOT NULL DEFAULT 0,
    visualizacoes INTEGER NOT NULL DEFAULT 0,
    favoritos INTEGER NOT NULL DEFAULT 0,
    
    -- Metadados
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    publicado_em TIMESTAMPTZ,
    
    -- Constraints
    CONSTRAINT chk_item_preco CHECK (
        (tipo = 'aluguel' AND (preco_por_dia > 0 OR preco_por_hora > 0)) OR
        (tipo = 'venda' AND preco_venda > 0) OR
        (tipo = 'ambos' AND (preco_por_dia > 0 OR preco_por_hora > 0) AND preco_venda > 0)
    ),
    CONSTRAINT chk_item_caucao CHECK (valor_caucao >= 0),
    CONSTRAINT chk_item_avaliacao CHECK (avaliacao_media >= 0 AND avaliacao_media <= 5),
    CONSTRAINT chk_item_tempo_aluguel CHECK (
        tempo_minimo_aluguel IS NULL OR tempo_maximo_aluguel IS NULL OR
        tempo_minimo_aluguel <= tempo_maximo_aluguel
    )
);

CREATE INDEX idx_itens_proprietario ON itens(proprietario_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_itens_categoria ON itens(categoria) WHERE deleted_at IS NULL AND status = 'ativo';
CREATE INDEX idx_itens_subcategoria ON itens(categoria, subcategoria) WHERE deleted_at IS NULL AND status = 'ativo';
CREATE INDEX idx_itens_localizacao ON itens(localizacao_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_itens_status ON itens(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_itens_tipo ON itens(tipo) WHERE deleted_at IS NULL AND status = 'ativo';
CREATE INDEX idx_itens_avaliacao ON itens(avaliacao_media DESC) WHERE deleted_at IS NULL AND status = 'ativo';
CREATE INDEX idx_itens_preco_dia ON itens(preco_por_dia ASC) WHERE deleted_at IS NULL AND status = 'ativo' AND preco_por_dia IS NOT NULL;

-- =============================================
-- AGREGADO: ALUGUEL (Root Aggregate)
-- =============================================
CREATE TYPE aluguel_status_enum AS ENUM (
    'pendente',           -- Aguardando aprovação do locador
    'aprovado',           -- Aprovado pelo locador, aguardando pagamento
    'pago',               -- Pagamento confirmado
    'ativo',              -- Aluguel em andamento
    'finalizado',         -- Aluguel concluído normalmente
    'cancelado',          -- Cancelado antes do início
    'cancelado_locador',  -- Cancelado pelo locador
    'cancelado_locatario',-- Cancelado pelo locatário
    'atrasado',           -- Devolução em atraso
    'disputado'           -- Em disputa/problema
);

CREATE TYPE caucao_status_enum AS ENUM ('pendente', 'bloqueado', 'liberado', 'retido_parcial', 'retido_total');
CREATE TYPE tipo_periodo_enum AS ENUM ('hora', 'dia');

CREATE TABLE alugueis (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Item (FK)
    item_id UUID NOT NULL REFERENCES itens(id) ON DELETE RESTRICT,
    
    -- Dados denormalizados do item (snapshot)
    item_nome VARCHAR(255) NOT NULL,
    item_foto_url VARCHAR(1024),
    item_categoria VARCHAR(100) NOT NULL,
    
    -- Locador (proprietário do item)
    locador_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    locador_nome VARCHAR(255) NOT NULL,
    locador_foto_url VARCHAR(1024),
    locador_telefone VARCHAR(20),
    
    -- Locatário (quem aluga)
    locatario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    locatario_nome VARCHAR(255) NOT NULL,
    locatario_foto_url VARCHAR(1024),
    locatario_telefone VARCHAR(20),
    
    -- Período do aluguel
    data_inicio TIMESTAMPTZ NOT NULL,
    data_fim TIMESTAMPTZ NOT NULL,
    data_retirada_real TIMESTAMPTZ,
    data_devolucao_real TIMESTAMPTZ,
    duracao INTEGER NOT NULL, -- Calculado em horas ou dias
    tipo_periodo tipo_periodo_enum NOT NULL,
    
    -- Valores
    preco_unitario DECIMAL(10,2) NOT NULL,
    quantidade_periodos INTEGER NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    taxa_servico DECIMAL(10,2) NOT NULL DEFAULT 0,
    desconto DECIMAL(10,2) NOT NULL DEFAULT 0,
    preco_total DECIMAL(10,2) NOT NULL,
    
    -- Status
    status aluguel_status_enum NOT NULL DEFAULT 'pendente',
    
    -- Caução (Value Object embutido)
    caucao_valor DECIMAL(10,2),
    caucao_status caucao_status_enum,
    caucao_metodo_pagamento VARCHAR(50),
    caucao_transacao_id VARCHAR(255),
    caucao_data_bloqueio TIMESTAMPTZ,
    caucao_data_liberacao TIMESTAMPTZ,
    caucao_valor_retido DECIMAL(10,2) DEFAULT 0,
    caucao_motivo_retencao TEXT,
    
    -- Contrato (FK opcional)
    contrato_id UUID,
    contrato_aceito BOOLEAN DEFAULT FALSE,
    contrato_aceito_em TIMESTAMPTZ,
    
    -- Observações e motivos
    observacoes_locatario TEXT,
    observacoes_locador TEXT,
    motivo_cancelamento TEXT,
    motivo_recusa TEXT,
    cancelado_por_id UUID REFERENCES usuarios(id) ON DELETE SET NULL,
    
    -- Metadados
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    
    -- Constraints
    CONSTRAINT chk_aluguel_datas CHECK (data_fim > data_inicio),
    CONSTRAINT chk_aluguel_valores CHECK (preco_total >= 0 AND subtotal >= 0),
    CONSTRAINT chk_aluguel_caucao CHECK (
        caucao_valor IS NULL OR 
        (caucao_valor >= 0 AND caucao_status IS NOT NULL)
    ),
    CONSTRAINT chk_aluguel_locador_locatario CHECK (locador_id != locatario_id)
);

CREATE INDEX idx_alugueis_item ON alugueis(item_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_alugueis_locador ON alugueis(locador_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_alugueis_locatario ON alugueis(locatario_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_alugueis_status ON alugueis(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_alugueis_datas ON alugueis(data_inicio, data_fim) WHERE deleted_at IS NULL;
CREATE INDEX idx_alugueis_ativo ON alugueis(item_id, status) WHERE deleted_at IS NULL AND status = 'ativo';
CREATE INDEX idx_alugueis_contrato ON alugueis(contrato_id) WHERE contrato_id IS NOT NULL;

-- =============================================
-- ENTIDADE: CONTRATO
-- =============================================
CREATE TABLE contratos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Relacionamentos
    aluguel_id UUID NOT NULL REFERENCES alugueis(id) ON DELETE CASCADE,
    locatario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    locador_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    item_id UUID NOT NULL REFERENCES itens(id) ON DELETE RESTRICT,
    
    -- Conteúdo do contrato
    conteudo_html TEXT NOT NULL,
    conteudo_pdf_url VARCHAR(1024),
    hash_conteudo VARCHAR(64) NOT NULL, -- SHA256 para integridade
    
    -- Versão e template
    versao_contrato VARCHAR(50) NOT NULL,
    template_id UUID,
    
    -- Assinaturas
    aceite_locatario BOOLEAN DEFAULT FALSE,
    aceite_locador BOOLEAN DEFAULT FALSE,
    data_aceite_locatario TIMESTAMPTZ,
    data_aceite_locador TIMESTAMPTZ,
    ip_aceite_locatario INET,
    ip_aceite_locador INET,
    
    -- Metadados
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_contrato_aceites CHECK (
        (aceite_locatario = FALSE OR data_aceite_locatario IS NOT NULL) AND
        (aceite_locador = FALSE OR data_aceite_locador IS NOT NULL)
    )
);

CREATE INDEX idx_contratos_aluguel ON contratos(aluguel_id);
CREATE UNIQUE INDEX idx_contratos_aluguel_versao ON contratos(aluguel_id, versao_contrato);

-- =============================================
-- ENTIDADE: VERIFICAÇÃO DE FOTOS
-- =============================================
CREATE TYPE momento_foto_enum AS ENUM ('retirada', 'devolucao');

CREATE TABLE verificacoes_fotos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Relacionamentos
    aluguel_id UUID NOT NULL REFERENCES alugueis(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES itens(id) ON DELETE RESTRICT,
    locatario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    locador_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    
    -- Fotos de retirada (início)
    fotos_retirada JSONB DEFAULT '[]', -- [{url, timestamp, uploaded_by}]
    fotos_retirada_count INTEGER DEFAULT 0,
    data_upload_retirada TIMESTAMPTZ,
    observacoes_retirada TEXT,
    responsavel_upload_retirada UUID REFERENCES usuarios(id),
    
    -- Fotos de devolução (fim)
    fotos_devolucao JSONB DEFAULT '[]',
    fotos_devolucao_count INTEGER DEFAULT 0,
    data_upload_devolucao TIMESTAMPTZ,
    observacoes_devolucao TEXT,
    responsavel_upload_devolucao UUID REFERENCES usuarios(id),
    
    -- Status
    retirada_completa BOOLEAN DEFAULT FALSE,
    devolucao_completa BOOLEAN DEFAULT FALSE,
    verificacao_completa BOOLEAN DEFAULT FALSE,
    
    -- Análise (opcional - pode ser feita por IA)
    divergencias_detectadas BOOLEAN DEFAULT FALSE,
    descricao_divergencias TEXT,
    
    -- Metadados
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_verificacoes_fotos_aluguel ON verificacoes_fotos(aluguel_id);
CREATE INDEX idx_verificacoes_fotos_item ON verificacoes_fotos(item_id);
CREATE INDEX idx_verificacoes_fotos_completa ON verificacoes_fotos(verificacao_completa);

-- =============================================
-- ENTIDADE: AVALIAÇÃO
-- =============================================
CREATE TYPE avaliacao_tipo_enum AS ENUM ('usuario', 'item');

CREATE TABLE avaliacoes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Avaliador
    avaliador_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    avaliador_nome VARCHAR(255) NOT NULL,
    avaliador_foto_url VARCHAR(1024),
    
    -- Avaliado (polimórfico)
    avaliado_id UUID NOT NULL,
    tipo_avaliado avaliacao_tipo_enum NOT NULL,
    
    -- Contexto
    aluguel_id UUID REFERENCES alugueis(id) ON DELETE SET NULL,
    item_id UUID REFERENCES itens(id) ON DELETE SET NULL,
    
    -- Avaliação
    nota DECIMAL(3,2) NOT NULL,
    comentario TEXT,
    
    -- Critérios específicos (opcionais)
    criterios JSONB, -- Ex: {comunicacao: 5, pontualidade: 4, estado_item: 5}
    
    -- Resposta do avaliado
    resposta TEXT,
    data_resposta TIMESTAMPTZ,
    
    -- Moderação
    denunciado BOOLEAN DEFAULT FALSE,
    moderado BOOLEAN DEFAULT FALSE,
    visivel BOOLEAN DEFAULT TRUE,
    motivo_ocultacao TEXT,
    
    -- Metadados
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    
    -- Constraints
    CONSTRAINT chk_avaliacao_nota CHECK (nota >= 0 AND nota <= 5),
    CONSTRAINT chk_avaliacao_tipo CHECK (
        (tipo_avaliado = 'usuario' AND avaliado_id IN (SELECT id FROM usuarios)) OR
        (tipo_avaliado = 'item' AND avaliado_id IN (SELECT id FROM itens))
    )
);

CREATE INDEX idx_avaliacoes_avaliador ON avaliacoes(avaliador_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_avaliacoes_avaliado ON avaliacoes(avaliado_id, tipo_avaliado) WHERE deleted_at IS NULL AND visivel = TRUE;
CREATE INDEX idx_avaliacoes_aluguel ON avaliacoes(aluguel_id) WHERE aluguel_id IS NOT NULL;
CREATE INDEX idx_avaliacoes_item ON avaliacoes(item_id) WHERE item_id IS NOT NULL;
CREATE INDEX idx_avaliacoes_nota ON avaliacoes(nota DESC) WHERE deleted_at IS NULL AND visivel = TRUE;
CREATE UNIQUE INDEX idx_avaliacoes_unico ON avaliacoes(avaliador_id, aluguel_id, tipo_avaliado) WHERE deleted_at IS NULL;

-- =============================================
-- ENTIDADE: DENÚNCIA
-- =============================================
CREATE TYPE denuncia_tipo_enum AS ENUM (
    'fraude',
    'dano_item',
    'comportamento_inadequado',
    'nao_devolucao',
    'atraso',
    'item_diferente',
    'item_quebrado',
    'uso_inadequado',
    'outro'
);

CREATE TYPE denuncia_status_enum AS ENUM (
    'aberta',
    'em_analise',
    'aguardando_informacoes',
    'resolvida',
    'rejeitada',
    'cancelada'
);

CREATE TABLE denuncias (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Contexto
    aluguel_id UUID REFERENCES alugueis(id) ON DELETE CASCADE,
    item_id UUID REFERENCES itens(id) ON DELETE SET NULL,
    
    -- Partes envolvidas
    denunciante_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    denunciado_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    
    -- Denúncia
    tipo denuncia_tipo_enum NOT NULL,
    titulo VARCHAR(255) NOT NULL,
    descricao TEXT NOT NULL,
    evidencias JSONB DEFAULT '[]', -- [{tipo: 'foto|video|documento', url, descricao}]
    
    -- Status e resolução
    status denuncia_status_enum NOT NULL DEFAULT 'aberta',
    prioridade VARCHAR(20) DEFAULT 'media', -- baixa, media, alta, critica
    
    -- Moderação
    moderador_id UUID REFERENCES usuarios(id) ON DELETE SET NULL,
    data_inicio_analise TIMESTAMPTZ,
    data_resolucao TIMESTAMPTZ,
    resolucao TEXT,
    acoes_tomadas JSONB, -- [{tipo: 'advertencia|suspensao|bloqueio', usuario_id, data}]
    
    -- Compensação (se aplicável)
    compensacao_aplicada BOOLEAN DEFAULT FALSE,
    valor_compensacao DECIMAL(10,2),
    descricao_compensacao TEXT,
    
    -- Metadados
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_denuncia_diferentes CHECK (denunciante_id != denunciado_id),
    CONSTRAINT chk_denuncia_resolucao CHECK (
        (status IN ('resolvida', 'rejeitada') AND data_resolucao IS NOT NULL) OR
        (status NOT IN ('resolvida', 'rejeitada'))
    )
);

CREATE INDEX idx_denuncias_aluguel ON denuncias(aluguel_id);
CREATE INDEX idx_denuncias_denunciante ON denuncias(denunciante_id);
CREATE INDEX idx_denuncias_denunciado ON denuncias(denunciado_id);
CREATE INDEX idx_denuncias_status ON denuncias(status);
CREATE INDEX idx_denuncias_tipo ON denuncias(tipo);
CREATE INDEX idx_denuncias_prioridade ON denuncias(prioridade, status) WHERE status IN ('aberta', 'em_analise');

-- =============================================
-- ENTIDADE: PROBLEMA
-- =============================================
CREATE TYPE problema_tipo_enum AS ENUM (
    'dano_item',
    'item_nao_funciona',
    'atraso_devolucao',
    'atraso_retirada',
    'item_diferente_anuncio',
    'limpeza',
    'pecas_faltando',
    'outro'
);

CREATE TYPE problema_prioridade_enum AS ENUM ('baixa', 'media', 'alta', 'critica');
CREATE TYPE problema_status_enum AS ENUM ('aberto', 'em_analise', 'resolvido', 'cancelado', 'escalado');

CREATE TABLE problemas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Contexto
    aluguel_id UUID NOT NULL REFERENCES alugueis(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES itens(id) ON DELETE RESTRICT,
    
    -- Partes envolvidas
    reportado_por_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    reportado_por_nome VARCHAR(255) NOT NULL,
    reportado_por_tipo VARCHAR(20) NOT NULL, -- 'locador' ou 'locatario'
    reportado_contra_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    
    -- Problema
    tipo problema_tipo_enum NOT NULL,
    titulo VARCHAR(255) NOT NULL,
    descricao TEXT NOT NULL,
    fotos JSONB DEFAULT '[]', -- [{url, timestamp, legenda}]
    
    -- Classificação
    prioridade problema_prioridade_enum NOT NULL DEFAULT 'media',
    status problema_status_enum NOT NULL DEFAULT 'aberto',
    
    -- Resolução
    data_resolucao TIMESTAMPTZ,
    resolucao TEXT,
    resolvido_por_id UUID REFERENCES usuarios(id),
    
    -- Impacto financeiro
    valor_estimado_dano DECIMAL(10,2),
    valor_acordado_reparacao DECIMAL(10,2),
    responsavel_pagamento UUID REFERENCES usuarios(id),
    
    -- Escalamento
    escalado BOOLEAN DEFAULT FALSE,
    data_escalamento TIMESTAMPTZ,
    moderador_id UUID REFERENCES usuarios(id),
    
    -- Metadados
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_problema_diferentes CHECK (reportado_por_id != reportado_contra_id),
    CONSTRAINT chk_problema_resolucao CHECK (
        (status = 'resolvido' AND data_resolucao IS NOT NULL) OR
        (status != 'resolvido')
    )
);

CREATE INDEX idx_problemas_aluguel ON problemas(aluguel_id);
CREATE INDEX idx_problemas_item ON problemas(item_id);
CREATE INDEX idx_problemas_reportado_por ON problemas(reportado_por_id);
CREATE INDEX idx_problemas_status ON problemas(status);
CREATE INDEX idx_problemas_prioridade ON problemas(prioridade, status) WHERE status IN ('aberto', 'em_analise');

-- =============================================
-- AGREGADO: CONVERSA/CHAT (Root Aggregate)
-- =============================================
CREATE TABLE conversas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Item relacionado
    item_id UUID NOT NULL REFERENCES itens(id) ON DELETE CASCADE,
    item_nome VARCHAR(255) NOT NULL,
    item_foto_url VARCHAR(1024),
    
    -- Participantes
    locador_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    locador_nome VARCHAR(255) NOT NULL,
    locador_foto_url VARCHAR(1024),
    locador_online BOOLEAN DEFAULT FALSE,
    locador_ultimo_acesso TIMESTAMPTZ,
    
    locatario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    locatario_nome VARCHAR(255) NOT NULL,
    locatario_foto_url VARCHAR(1024),
    locatario_online BOOLEAN DEFAULT FALSE,
    locatario_ultimo_acesso TIMESTAMPTZ,
    
    -- Última mensagem (denormalizado para lista de conversas)
    ultima_mensagem_texto TEXT,
    ultima_mensagem_tipo VARCHAR(50),
    ultima_mensagem_remetente_id UUID,
    ultima_mensagem_data TIMESTAMPTZ,
    
    -- Mensagens não lidas
    mensagens_nao_lidas_locador INTEGER DEFAULT 0,
    mensagens_nao_lidas_locatario INTEGER DEFAULT 0,
    
    -- Status
    arquivada_locador BOOLEAN DEFAULT FALSE,
    arquivada_locatario BOOLEAN DEFAULT FALSE,
    bloqueada BOOLEAN DEFAULT FALSE,
    
    -- Aluguel associado (opcional)
    aluguel_id UUID REFERENCES alugueis(id) ON DELETE SET NULL,
    
    -- Metadados
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_conversa_participantes CHECK (locador_id != locatario_id)
);

CREATE INDEX idx_conversas_item ON conversas(item_id);
CREATE INDEX idx_conversas_locador ON conversas(locador_id, updated_at DESC);
CREATE INDEX idx_conversas_locatario ON conversas(locatario_id, updated_at DESC);
CREATE INDEX idx_conversas_nao_lidas_locador ON conversas(locador_id) WHERE mensagens_nao_lidas_locador > 0;
CREATE INDEX idx_conversas_nao_lidas_locatario ON conversas(locatario_id) WHERE mensagens_nao_lidas_locatario > 0;
CREATE UNIQUE INDEX idx_conversas_unica ON conversas(item_id, locador_id, locatario_id);

-- =============================================
-- ENTIDADE: MENSAGEM
-- =============================================
CREATE TYPE mensagem_tipo_enum AS ENUM (
    'texto',
    'imagem',
    'video',
    'audio',
    'arquivo',
    'localizacao',
    'proposta_aluguel',
    'sistema'
);

CREATE TABLE mensagens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Conversa
    conversa_id UUID NOT NULL REFERENCES conversas(id) ON DELETE CASCADE,
    
    -- Remetente
    remetente_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    remetente_nome VARCHAR(255) NOT NULL,
    
    -- Conteúdo
    conteudo TEXT,
    tipo mensagem_tipo_enum NOT NULL DEFAULT 'texto',
    
    -- Anexos
    anexo_url VARCHAR(1024),
    anexo_tipo VARCHAR(50), -- mime type
    anexo_tamanho INTEGER, -- bytes
    anexo_nome VARCHAR(255),
    
    -- Metadados adicionais (para mensagens especiais)
    metadata JSONB, -- Ex: {proposta_id, valor, datas} para proposta_aluguel
    
    -- Status
    lida BOOLEAN DEFAULT FALSE,
    data_leitura TIMESTAMPTZ,
    entregue BOOLEAN DEFAULT TRUE,
    
    -- Moderação
    editada BOOLEAN DEFAULT FALSE,
    data_edicao TIMESTAMPTZ,
    deletada BOOLEAN DEFAULT FALSE,
    data_delecao TIMESTAMPTZ,
    
    -- Metadados
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_mensagem_conteudo CHECK (
        (tipo = 'texto' AND conteudo IS NOT NULL) OR
        (tipo != 'texto')
    )
);

CREATE INDEX idx_mensagens_conversa ON mensagens(conversa_id, created_at DESC);
CREATE INDEX idx_mensagens_remetente ON mensagens(remetente_id);
CREATE INDEX idx_mensagens_nao_lidas ON mensagens(conversa_id, lida) WHERE lida = FALSE AND deletada = FALSE;

-- =============================================
-- ENTIDADE: MULTA
-- =============================================
CREATE TYPE multa_tipo_enum AS ENUM ('atraso_devolucao', 'dano', 'limpeza', 'outro');
CREATE TYPE multa_status_enum AS ENUM ('pendente', 'notificado', 'pago', 'cancelado', 'contestado', 'em_disputa');

CREATE TABLE multas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Contexto
    aluguel_id UUID NOT NULL REFERENCES alugueis(id) ON DELETE CASCADE,
    locatario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT, -- Quem deve pagar
    locador_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,   -- Quem recebe
    
    -- Tipo e valores
    tipo multa_tipo_enum NOT NULL DEFAULT 'atraso_devolucao',
    descricao TEXT NOT NULL,
    
    -- Cálculo (para atraso)
    dias_atraso INTEGER,
    horas_atraso INTEGER,
    valor_diaria DECIMAL(10,2),
    multiplicador DECIMAL(5,2) DEFAULT 1.0,
    
    -- Valores
    valor_base DECIMAL(10,2) NOT NULL,
    valor_adicional DECIMAL(10,2) DEFAULT 0,
    valor_total DECIMAL(10,2) NOT NULL,
    valor_pago DECIMAL(10,2) DEFAULT 0,
    
    -- Status
    status multa_status_enum NOT NULL DEFAULT 'pendente',
    
    -- Pagamento
    metodo_pagamento VARCHAR(50),
    transacao_id VARCHAR(255),
    data_pagamento TIMESTAMPTZ,
    comprovante_url VARCHAR(1024),
    
    -- Contestação
    contestada BOOLEAN DEFAULT FALSE,
    data_contestacao TIMESTAMPTZ,
    motivo_contestacao TEXT,
    resultado_contestacao TEXT,
    
    -- Metadados
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_multa_valor CHECK (valor_total > 0 AND valor_pago >= 0 AND valor_pago <= valor_total),
    CONSTRAINT chk_multa_diferentes CHECK (locatario_id != locador_id)
);

CREATE INDEX idx_multas_aluguel ON multas(aluguel_id);
CREATE INDEX idx_multas_locatario ON multas(locatario_id);
CREATE INDEX idx_multas_locador ON multas(locador_id);
CREATE INDEX idx_multas_status ON multas(status);

-- =============================================
-- ENTIDADE: NOTIFICAÇÃO
-- =============================================
CREATE TYPE notificacao_tipo_enum AS ENUM (
    -- Aluguel
    'aluguel_solicitado',
    'aluguel_aprovado',
    'aluguel_recusado',
    'aluguel_cancelado',
    'aluguel_iniciado',
    'aluguel_finalizado',
    'aluguel_proximo_inicio',
    'aluguel_proximo_fim',
    'aluguel_atrasado',
    
    -- Pagamento
    'pagamento_pendente',
    'pagamento_confirmado',
    'pagamento_falhou',
    'reembolso_processado',
    
    -- Caução
    'caucao_bloqueada',
    'caucao_liberada',
    'caucao_retida',
    
    -- Chat
    'nova_mensagem',
    
    -- Avaliação
    'nova_avaliacao',
    'resposta_avaliacao',
    
    -- Problemas
    'problema_reportado',
    'problema_resolvido',
    
    -- Sistema
    'verificacao_pendente',
    'verificacao_aprovada',
    'verificacao_rejeitada',
    'conta_suspensa',
    'conta_reativada',
    
    -- Outros
    'lembrete',
    'sistema'
);

CREATE TYPE notificacao_prioridade_enum AS ENUM ('baixa', 'normal', 'alta', 'urgente');

CREATE TABLE notificacoes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Destinatário
    destinatario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    
    -- Tipo e conteúdo
    tipo notificacao_tipo_enum NOT NULL,
    prioridade notificacao_prioridade_enum DEFAULT 'normal',
    titulo VARCHAR(255) NOT NULL,
    mensagem TEXT NOT NULL,
    
    -- Ação (deep link ou URL)
    acao_url VARCHAR(512),
    acao_tipo VARCHAR(50), -- 'aluguel', 'chat', 'perfil', etc
    acao_id UUID, -- ID da entidade relacionada
    
    -- Contexto
    aluguel_id UUID REFERENCES alugueis(id) ON DELETE SET NULL,
    item_id UUID REFERENCES itens(id) ON DELETE SET NULL,
    remetente_id UUID REFERENCES usuarios(id) ON DELETE SET NULL,
    
    -- Dados adicionais
    dados JSONB, -- Payload extra para renderização dinâmica
    
    -- Status
    lida BOOLEAN DEFAULT FALSE,
    data_leitura TIMESTAMPTZ,
    enviada_push BOOLEAN DEFAULT FALSE,
    enviada_email BOOLEAN DEFAULT FALSE,
    
    -- Agendamento
    agendada BOOLEAN DEFAULT FALSE,
    data_agendamento TIMESTAMPTZ,
    
    -- Expiração
    expira_em TIMESTAMPTZ,
    
    -- Metadados
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_notificacoes_destinatario ON notificacoes(destinatario_id, created_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_notificacoes_nao_lidas ON notificacoes(destinatario_id, lida) WHERE lida = FALSE AND deleted_at IS NULL;
CREATE INDEX idx_notificacoes_aluguel ON notificacoes(aluguel_id) WHERE aluguel_id IS NOT NULL;
CREATE INDEX idx_notificacoes_tipo ON notificacoes(tipo, created_at DESC);
CREATE INDEX idx_notificacoes_agendadas ON notificacoes(data_agendamento) WHERE agendada = TRUE AND deleted_at IS NULL;

-- =============================================
-- ENTIDADE: AUTENTICAÇÃO (Firebase Auth Integration)
-- =============================================
CREATE TABLE auth_providers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Usuário relacionado
    usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    
    -- Provider de autenticação
    provider VARCHAR(50) NOT NULL, -- 'firebase', 'google', 'apple', 'email'
    provider_uid VARCHAR(255) NOT NULL, -- UID do provider
    
    -- Dados do provider
    email VARCHAR(255),
    display_name VARCHAR(255),
    photo_url VARCHAR(1024),
    
    -- Tokens (opcional - para refresh tokens)
    refresh_token TEXT,
    access_token TEXT,
    token_expires_at TIMESTAMPTZ,
    
    -- Status
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    ultimo_login TIMESTAMPTZ,
    
    -- Metadados
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT uq_auth_provider UNIQUE (provider, provider_uid),
    CONSTRAINT uq_usuario_provider UNIQUE (usuario_id, provider)
);

CREATE INDEX idx_auth_providers_usuario ON auth_providers(usuario_id);
CREATE INDEX idx_auth_providers_provider_uid ON auth_providers(provider, provider_uid);
CREATE INDEX idx_auth_providers_ativo ON auth_providers(ativo) WHERE ativo = TRUE;

-- =============================================
-- ENTIDADE: SESSÕES (Opcional - para sessões customizadas)
-- =============================================
CREATE TABLE sessoes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Usuário
    usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    
    -- Dados da sessão
    session_token VARCHAR(255) UNIQUE NOT NULL,
    refresh_token VARCHAR(255) UNIQUE,
    
    -- Dispositivo
    device_info JSONB, -- {platform, browser, ip, user_agent}
    device_fingerprint VARCHAR(255),
    
    -- Controle de acesso
    expires_at TIMESTAMPTZ NOT NULL,
    refresh_expires_at TIMESTAMPTZ,
    revoked BOOLEAN DEFAULT FALSE,
    revoked_at TIMESTAMPTZ,
    motivo_revogacao TEXT,
    
    -- Localização (opcional)
    ip_address INET,
    location JSONB, -- {country, city, coordinates}
    
    -- Metadados
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_sessao_expiracao CHECK (expires_at > created_at)
);

CREATE INDEX idx_sessoes_usuario ON sessoes(usuario_id, created_at DESC);
CREATE INDEX idx_sessoes_token ON sessoes(session_token);
CREATE INDEX idx_sessoes_refresh_token ON sessoes(refresh_token);
CREATE INDEX idx_sessoes_expires ON sessoes(expires_at) WHERE revoked = FALSE;
CREATE INDEX idx_sessoes_ativa ON sessoes(usuario_id, last_activity DESC) WHERE revoked = FALSE AND expires_at > CURRENT_TIMESTAMP;

-- =============================================
-- ENTIDADE: PAGAMENTOS
-- =============================================
CREATE TYPE pagamento_tipo_enum AS ENUM ('aluguel', 'caucao', 'multa', 'reembolso', 'compensacao');
CREATE TYPE pagamento_status_enum AS ENUM ('pendente', 'processando', 'aprovado', 'falhou', 'cancelado', 'reembolsado');
CREATE TYPE pagamento_metodo_enum AS ENUM ('pix', 'cartao_credito', 'cartao_debito', 'boleto', 'transferencia');

CREATE TABLE pagamentos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Tipo e contexto
    tipo pagamento_tipo_enum NOT NULL,
    aluguel_id UUID REFERENCES alugueis(id) ON DELETE SET NULL,
    multa_id UUID REFERENCES multas(id) ON DELETE SET NULL,
    
    -- Partes envolvidas
    pagador_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    recebedor_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    
    -- Valores
    valor_bruto DECIMAL(10,2) NOT NULL,
    taxa_plataforma DECIMAL(10,2) DEFAULT 0,
    taxa_pagamento DECIMAL(10,2) DEFAULT 0,
    valor_liquido DECIMAL(10,2) NOT NULL,
    
    -- Método de pagamento
    metodo pagamento_metodo_enum NOT NULL,
    
    -- Status e processamento
    status pagamento_status_enum NOT NULL DEFAULT 'pendente',
    
    -- Integração com gateway
    gateway_provider VARCHAR(50), -- 'mercadopago', 'stripe', etc
    gateway_transacao_id VARCHAR(255),
    gateway_response JSONB,
    
    -- Dados do pagamento
    pix_chave VARCHAR(255),
    pix_qrcode TEXT,
    boleto_url VARCHAR(1024),
    boleto_codigo_barras VARCHAR(255),
    cartao_ultimos_digitos VARCHAR(4),
    cartao_bandeira VARCHAR(50),
    
    -- Datas importantes
    data_vencimento TIMESTAMPTZ,
    data_pagamento TIMESTAMPTZ,
    data_compensacao TIMESTAMPTZ,
    
    -- Reembolso
    reembolsado BOOLEAN DEFAULT FALSE,
    data_reembolso TIMESTAMPTZ,
    motivo_reembolso TEXT,
    
    -- Metadados
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_pagamento_valores CHECK (valor_bruto > 0 AND valor_liquido > 0),
    CONSTRAINT chk_pagamento_diferentes CHECK (pagador_id != recebedor_id)
);

CREATE INDEX idx_pagamentos_aluguel ON pagamentos(aluguel_id);
CREATE INDEX idx_pagamentos_pagador ON pagamentos(pagador_id);
CREATE INDEX idx_pagamentos_recebedor ON pagamentos(recebedor_id);
CREATE INDEX idx_pagamentos_status ON pagamentos(status);
CREATE INDEX idx_pagamentos_gateway ON pagamentos(gateway_transacao_id) WHERE gateway_transacao_id IS NOT NULL;

-- =============================================
-- ENTIDADE: DISPONIBILIDADE (Calendário de itens)
-- =============================================
CREATE TYPE disponibilidade_tipo_enum AS ENUM ('disponivel', 'bloqueado', 'alugado', 'manutencao');

CREATE TABLE disponibilidades (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    item_id UUID NOT NULL REFERENCES itens(id) ON DELETE CASCADE,
    aluguel_id UUID REFERENCES alugueis(id) ON DELETE SET NULL,
    
    -- Período
    data_inicio TIMESTAMPTZ NOT NULL,
    data_fim TIMESTAMPTZ NOT NULL,
    
    -- Status
    tipo disponibilidade_tipo_enum NOT NULL,
    motivo TEXT,
    
    -- Configurações
    recorrente BOOLEAN DEFAULT FALSE,
    regra_recorrencia JSONB, -- Ex: {tipo: 'semanal', dias: [0,6]} para finais de semana
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_disponibilidade_datas CHECK (data_fim > data_inicio)
);

CREATE INDEX idx_disponibilidades_item ON disponibilidades(item_id, data_inicio, data_fim);
CREATE INDEX idx_disponibilidades_periodo ON disponibilidades(data_inicio, data_fim);
CREATE INDEX idx_disponibilidades_aluguel ON disponibilidades(aluguel_id) WHERE aluguel_id IS NOT NULL;

-- =============================================
-- ENTIDADE: AUDIT LOG (Auditoria de ações)
-- =============================================
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Entidade auditada
    entidade_tipo VARCHAR(50) NOT NULL, -- 'usuario', 'item', 'aluguel', etc
    entidade_id UUID NOT NULL,
    
    -- Ação
    acao VARCHAR(50) NOT NULL, -- 'create', 'update', 'delete', 'status_change', etc
    descricao TEXT,
    
    -- Ator
    usuario_id UUID REFERENCES usuarios(id) ON DELETE SET NULL,
    usuario_nome VARCHAR(255),
    usuario_tipo VARCHAR(50), -- 'usuario', 'admin', 'sistema'
    
    -- Dados
    dados_anteriores JSONB,
    dados_novos JSONB,
    diff JSONB, -- Diferenças específicas
    
    -- Contexto
    ip_address INET,
    user_agent TEXT,
    origem VARCHAR(50), -- 'web', 'mobile', 'api', 'sistema'
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_logs_entidade ON audit_logs(entidade_tipo, entidade_id, created_at DESC);
CREATE INDEX idx_audit_logs_usuario ON audit_logs(usuario_id, created_at DESC);
CREATE INDEX idx_audit_logs_acao ON audit_logs(acao, created_at DESC);

-- =============================================
-- FOREIGN KEY: Adiciona FK de contrato em alugueis
-- =============================================
ALTER TABLE alugueis 
ADD CONSTRAINT fk_alugueis_contrato 
FOREIGN KEY (contrato_id) REFERENCES contratos(id) ON DELETE SET NULL;

-- =============================================
-- TRIGGERS: Updated_at automático
-- =============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Aplica trigger em todas as tabelas com updated_at
CREATE TRIGGER update_enderecos_updated_at BEFORE UPDATE ON enderecos FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_usuarios_updated_at BEFORE UPDATE ON usuarios FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_verificacoes_telefone_updated_at BEFORE UPDATE ON verificacoes_telefone FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_verificacoes_residencia_updated_at BEFORE UPDATE ON verificacoes_residencia FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_itens_updated_at BEFORE UPDATE ON itens FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_alugueis_updated_at BEFORE UPDATE ON alugueis FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_contratos_updated_at BEFORE UPDATE ON contratos FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_verificacoes_fotos_updated_at BEFORE UPDATE ON verificacoes_fotos FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_avaliacoes_updated_at BEFORE UPDATE ON avaliacoes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_denuncias_updated_at BEFORE UPDATE ON denuncias FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_problemas_updated_at BEFORE UPDATE ON problemas FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_conversas_updated_at BEFORE UPDATE ON conversas FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_multas_updated_at BEFORE UPDATE ON multas FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_notificacoes_updated_at BEFORE UPDATE ON notificacoes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_pagamentos_updated_at BEFORE UPDATE ON pagamentos FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_disponibilidades_updated_at BEFORE UPDATE ON disponibilidades FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- VIEWS: Views úteis para consultas comuns
-- =============================================

-- View: Alugueis com informações completas
CREATE OR REPLACE VIEW vw_alugueis_completos AS
SELECT 
    a.*,
    i.nome as item_nome_atual,
    i.categoria as item_categoria_atual,
    u_locador.nome as locador_nome_atual,
    u_locador.reputacao as locador_reputacao,
    u_locatario.nome as locatario_nome_atual,
    u_locatario.reputacao as locatario_reputacao,
    c.aceite_locador as contrato_aceito_locador,
    c.aceite_locatario as contrato_aceito_locatario
FROM alugueis a
LEFT JOIN itens i ON a.item_id = i.id
LEFT JOIN usuarios u_locador ON a.locador_id = u_locador.id
LEFT JOIN usuarios u_locatario ON a.locatario_id = u_locatario.id
LEFT JOIN contratos c ON a.contrato_id = c.id
WHERE a.deleted_at IS NULL;

-- View: Itens disponíveis com localização
CREATE OR REPLACE VIEW vw_itens_disponiveis AS
SELECT 
    i.*,
    e.cidade,
    e.estado,
    e.latitude,
    e.longitude,
    u.nome as proprietario_nome_atual,
    u.reputacao as proprietario_reputacao_atual,
    COUNT(DISTINCT f.id) as total_favoritos_atual
FROM itens i
JOIN enderecos e ON i.localizacao_id = e.id
JOIN usuarios u ON i.proprietario_id = u.id
LEFT JOIN favoritos f ON i.id = f.item_id
WHERE i.deleted_at IS NULL 
  AND i.status = 'ativo'
  AND u.ativo = TRUE 
  AND u.bloqueado = FALSE
GROUP BY i.id, e.id, u.id;

-- =============================================
-- COMENTÁRIOS: Documentação das tabelas
-- =============================================
COMMENT ON TABLE usuarios IS 'Agregado raiz: Usuários da plataforma (locadores e locatários)';
COMMENT ON TABLE itens IS 'Agregado raiz: Itens disponíveis para aluguel ou venda';
COMMENT ON TABLE alugueis IS 'Agregado raiz: Transações de aluguel entre usuários';
COMMENT ON TABLE conversas IS 'Agregado raiz: Conversas/chats entre usuários sobre itens';
COMMENT ON TABLE enderecos IS 'Value Object: Endereços compartilhados';
COMMENT ON TABLE contratos IS 'Entidade: Contratos digitais dos alugueis';
COMMENT ON TABLE avaliacoes IS 'Entidade: Avaliações de usuários e itens';
COMMENT ON TABLE pagamentos IS 'Entidade: Registro de todas as transações financeiras';
COMMENT ON TABLE notificacoes IS 'Entidade: Notificações push/email para usuários';
COMMENT ON TABLE audit_logs IS 'Entidade: Log de auditoria de todas as ações importantes';