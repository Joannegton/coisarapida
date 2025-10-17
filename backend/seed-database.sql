-- Script para popular tabelas com dados de teste
-- Execute após criar as tabelas com o script create-database.sql

-- =============================================
-- INSERIR USUÁRIOS DE TESTE
-- =============================================
INSERT INTO usuarios (id, nome, email, telefone, cpf, foto_url, endereco_id, email_verificado, telefone_verificado, residencia_verificada, verificado, ativo, bloqueado, reputacao, total_avaliacoes, created_at, updated_at) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'João Silva', 'joao.silva@email.com', '+5511999999999', '12345678901', 'https://cloudinary.com/foto1.jpg', NULL, true, true, false, false, true, false, 4.5, 10, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('550e8400-e29b-41d4-a716-446655440002', 'Maria Santos', 'maria.santos@email.com', '+5511988888888', '23456789012', 'https://cloudinary.com/foto2.jpg', NULL, true, false, true, true, true, false, 4.8, 25, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('550e8400-e29b-41d4-a716-446655440003', 'Pedro Oliveira', 'pedro.oliveira@email.com', '+5511977777777', '34567890123', 'https://cloudinary.com/foto3.jpg', NULL, true, true, true, true, true, false, 4.2, 15, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('550e8400-e29b-41d4-a716-446655440004', 'Ana Costa', 'ana.costa@email.com', '+5511966666666', '45678901234', 'https://cloudinary.com/foto4.jpg', NULL, true, true, false, false, true, false, 3.9, 8, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- =============================================
-- INSERIR VERIFICAÇÕES DE RESIDÊNCIA DE TESTE
-- =============================================
INSERT INTO verificacoes_residencia (id, usuario_id, endereco_id, comprovante_url, tipo_comprovante, status, moderador_id, observacoes_usuario, observacoes_moderador, motivo_rejeicao, data_submissao, data_inicio_analise, data_conclusao, created_at, updated_at) VALUES
('660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', NULL, 'https://cloudinary.com/comprovante1.jpg', 'conta_luz', 'pendente', NULL, 'Comprovante de residência recente', NULL, NULL, CURRENT_TIMESTAMP - INTERVAL '2 hours', NULL, NULL, CURRENT_TIMESTAMP - INTERVAL '2 hours', CURRENT_TIMESTAMP - INTERVAL '2 hours'),
('660e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440004', NULL, 'https://cloudinary.com/comprovante2.jpg', 'conta_agua', 'em_analise', '550e8400-e29b-41d4-a716-446655440002', 'Documento oficial de residência', 'Verificando autenticidade', NULL, CURRENT_TIMESTAMP - INTERVAL '1 day', CURRENT_TIMESTAMP - INTERVAL '2 hours', NULL, CURRENT_TIMESTAMP - INTERVAL '1 day', CURRENT_TIMESTAMP - INTERVAL '2 hours'),
('660e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440003', NULL, 'https://cloudinary.com/comprovante3.jpg', 'contrato', 'aprovado', '550e8400-e29b-41d4-a716-446655440002', NULL, 'Documento válido e endereço confirmado', NULL, CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '2 days', CURRENT_TIMESTAMP - INTERVAL '1 day', CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '1 day'),
('660e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440004', NULL, 'https://cloudinary.com/comprovante4.jpg', 'conta_luz', 'rejeitado', '550e8400-e29b-41d4-a716-446655440003', 'Tentativa de verificação', 'Documento ilegível e endereço não corresponde', 'Documento não legível', CURRENT_TIMESTAMP - INTERVAL '5 days', CURRENT_TIMESTAMP - INTERVAL '4 days', CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '5 days', CURRENT_TIMESTAMP - INTERVAL '3 days');

-- =============================================
-- INSERIR NOTIFICAÇÕES DE TESTE
-- =============================================
INSERT INTO notificacoes (id, destinatario_id, tipo, prioridade, titulo, mensagem, acao_url, acao_tipo, acao_id, aluguel_id, item_id, remetente_id, dados, lida, enviada_push, enviada_email, agendada, created_at, updated_at) VALUES
('770e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'verificacao_pendente', 'normal', 'Verificação em análise', 'Seu comprovante de residência está sendo analisado. Você será notificado em até 48h.', NULL, NULL, NULL, NULL, NULL, NULL, '{"tipo": "residencia"}', false, false, false, false, CURRENT_TIMESTAMP - INTERVAL '2 hours', CURRENT_TIMESTAMP - INTERVAL '2 hours'),
('770e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440004', 'verificacao_pendente', 'normal', 'Verificação em análise', 'Seu comprovante de residência está sendo analisado. Você será notificado em até 48h.', NULL, NULL, NULL, NULL, NULL, NULL, '{"tipo": "residencia"}', false, false, false, false, CURRENT_TIMESTAMP - INTERVAL '1 day', CURRENT_TIMESTAMP - INTERVAL '1 day'),
('770e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440003', 'verificacao_aprovada', 'alta', 'Verificação aprovada! ✅', 'Seu comprovante de residência foi verificado com sucesso!', NULL, NULL, NULL, NULL, NULL, NULL, '{"aprovado": true}', true, true, true, false, CURRENT_TIMESTAMP - INTERVAL '1 day', CURRENT_TIMESTAMP - INTERVAL '1 day'),
('770e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440004', 'verificacao_rejeitada', 'alta', 'Verificação rejeitada', 'Sua verificação foi rejeitada. Motivo: Documento não legível', NULL, NULL, NULL, NULL, NULL, NULL, '{"aprovado": false, "motivo": "Documento não legível"}', true, true, true, false, CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '3 days');

-- =============================================
-- VERIFICAR INSERÇÕES
-- =============================================
SELECT 'Usuarios inseridos:' as info, COUNT(*) as quantidade FROM usuarios;
SELECT 'Verificações inseridas:' as info, COUNT(*) as quantidade FROM verificacoes_residencia;
SELECT 'Notificações inseridas:' as info, COUNT(*) as quantidade FROM notificacoes;
