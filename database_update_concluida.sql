-- Script para adicionar as colunas 'concluida' e 'data_conclusao' na tabela atividades
-- Execute este script no Supabase SQL Editor

ALTER TABLE atividades 
ADD COLUMN IF NOT EXISTS concluida BOOLEAN DEFAULT false;

ALTER TABLE atividades 
ADD COLUMN IF NOT EXISTS data_conclusao TIMESTAMP;

-- Opcional: Criar índices para melhorar performance de consultas
CREATE INDEX IF NOT EXISTS idx_atividades_concluida 
ON atividades(concluida);

CREATE INDEX IF NOT EXISTS idx_atividades_recorrente_concluida 
ON atividades(recorrente, concluida) 
WHERE recorrente = true AND concluida = true;

-- Verificar se as colunas foram criadas
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'atividades' 
AND column_name IN ('concluida', 'data_conclusao');
