#!/bin/bash
set -e;

# Configurações para o banco de dados n8n
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Configurações básicas
    CREATE EXTENSION IF NOT EXISTS pgcrypto;
    
    -- Otimizações para o n8n
    ALTER SYSTEM SET max_connections = '200';
    ALTER SYSTEM SET shared_buffers = '256MB';
    ALTER SYSTEM SET work_mem = '16MB';
    
    -- Confirma a inicialização do banco
    SELECT 'Inicialização do banco de dados n8n concluída!' AS info;
EOSQL

echo "SETUP INFO: Banco de dados n8n inicializado com sucesso!"
