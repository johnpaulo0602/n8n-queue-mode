# n8n Scalable Setup Documentation

## Arquitetura do Sistema

Esta documentação descreve a configuração de alta escalabilidade do n8n implantada neste projeto, abordando cada componente, seu papel e as configurações disponíveis para otimização.

### Visão Geral

A arquitetura implementa um sistema n8n escalável com quatro componentes principais:

![Arquitetura n8n Escalável](https://docs.n8n.io/_images/hosting/scaling/queue-mode-flow.png)

1. **Editor**: Interface de usuário e API central
2. **Webhook**: Processa requisições webhook de forma distribuída
3. **Worker**: Executa workflows enfileirados
4. **Banco de Dados e Message Broker**: PostgreSQL e Redis para persistência e comunicação

## Componentes do Docker Compose

### PostgreSQL (postgres)

O PostgreSQL atua como o banco de dados principal para o n8n, armazenando:
- Workflows
- Credenciais (criptografadas)
- Histórico de execuções
- Configurações do sistema

**Variáveis relevantes:**
```
POSTGRES_USER: Nome do usuário principal do PostgreSQL
POSTGRES_PASSWORD: Senha do usuário principal
POSTGRES_DB: Nome do banco de dados usado pelo n8n
```

**Considerações de performance:**
- Para ambientes de alta demanda, considere aumentar `max_connections` 
- O PostgreSQL mantém uma transação para cada execução de workflow

### Redis (redis)

O Redis atua como message broker, permitindo a comunicação entre componentes:
- Gerencia a fila de execuções pendentes
- Coordena a distribuição de trabalho entre workers
- Permite escalonamento horizontal dos componentes

**Configurações importantes:**
```
QUEUE_BULL_REDIS_HOST: Hostname do Redis
QUEUE_BULL_REDIS_PORT: Porta do Redis (padrão: 6379)
QUEUE_BULL_REDIS_DB: Banco de dados do Redis usado pelo n8n (padrão: 0)
```

**Considerações de persistência:**
- O comando `redis-server --appendonly yes` garante persistência dos dados
- Em caso de falha, as execuções em andamento podem ser recuperadas

### Editor (n8n-editor)

O Editor é o componente principal que:
- Serve a interface web do n8n
- Gerencia a API REST
- Manipula autenticação de usuários
- Inicializa e configura o sistema

**Variáveis principais:**
```
N8N_HOST: Hostname para acesso ao editor
N8N_PORT: Porta para acesso ao editor (padrão: 5678)
N8N_PROTOCOL: Protocolo de acesso (http/https)
WEBHOOK_URL: URL completa para webhooks, importante para proxy reverso
N8N_DISABLE_PRODUCTION_MAIN_PROCESS: Se true, desativa o processamento de webhooks no processo principal
```

**Segurança e configurações avançadas:**
```
N8N_TRUSTED_PROXIES: Define quais proxies são confiáveis ('*' para todos)
N8N_TRUST_PROXY: Habilita suporte para cabeçalhos de proxy como X-Forwarded-For
N8N_ENCRYPTION_KEY: Chave para criptografia de credenciais (muito importante manter segura)
```

### Webhook Processor (n8n-webhook)

O Processor de Webhook:
- Processa exclusivamente requisições de webhook
- Escala horizontalmente para lidar com alto volume de requisições
- Envia eventos para serem processados pelos workers

**Configurações específicas:**
```
command: webhook (define que este contêiner atuará como processador de webhook)
N8N_WEBHOOK_URL: URL base para webhooks
```

**Escalabilidade:**
- É possível adicionar múltiplos webhook processors para alta disponibilidade
- O roteamento via Traefik distribui o tráfego entre as instâncias

### Worker (n8n-worker)

Os Workers:
- Executam workflows enfileirados
- Processam dados e interagem com sistemas externos
- Operam de forma independente, permitindo escalabilidade horizontal

**Variáveis específicas:**
```
command: worker (define que este contêiner atuará como worker)
QUEUE_WORKER_CONCURRENCY: Número de workflows que podem ser executados simultaneamente por worker
```

**Considerações de escalabilidade:**
- Adicione mais workers para aumentar o throughput do sistema
- Ajuste a concorrência com base nos recursos disponíveis (CPU/memória)

## Variáveis de Ambiente Detalhadas

### PostgreSQL e Banco de Dados

| Variável | Propósito | Opções |
|----------|-----------|--------|
| `DB_TYPE` | Define o tipo de banco de dados | `postgresdb` (recomendado), `sqlite` (não recomendado para produção) |
| `DB_POSTGRESDB_HOST` | Hostname do PostgreSQL | Hostname ou IP |
| `DB_POSTGRESDB_PORT` | Porta do PostgreSQL | Numérico (default: 5432) |
| `DB_POSTGRESDB_DATABASE` | Nome do banco de dados | String |
| `DB_POSTGRESDB_USER` | Usuário do PostgreSQL | String |
| `DB_POSTGRESDB_PASSWORD` | Senha do PostgreSQL | String |
| `DB_POSTGRESDB_SCHEMA` | Schema do PostgreSQL | String (default: "public") |
| `DB_POSTGRESDB_SSL_CA` | Certificado CA para SSL | Caminho para o arquivo |
| `DB_POSTGRESDB_SSL_CERT` | Certificado cliente SSL | Caminho para o arquivo |
| `DB_POSTGRESDB_SSL_KEY` | Chave privada SSL | Caminho para o arquivo |

### Redis e Sistema de Filas

| Variável | Propósito | Opções |
|----------|-----------|--------|
| `QUEUE_BULL_REDIS_HOST` | Hostname do Redis | Hostname ou IP |
| `QUEUE_BULL_REDIS_PORT` | Porta do Redis | Numérico (default: 6379) |
| `QUEUE_BULL_REDIS_DB` | Banco de dados Redis | Numérico (default: 0) |
| `QUEUE_BULL_REDIS_PASSWORD` | Senha do Redis | String |
| `QUEUE_HEALTH_CHECK_ACTIVE` | Ativa verificações de saúde | `true`/`false` |
| `QUEUE_HEALTH_CHECK_PORT` | Porta para health checks | Numérico |
| `QUEUE_WORKER_CONCURRENCY` | Concorrência por worker | Numérico (recomendado: 5-10) |
| `EXECUTIONS_MODE` | Modo de execução | `regular` (padrão) ou `queue` (distribuído) |

### Configuração de URLs e Acesso

| Variável | Propósito | Opções |
|----------|-----------|--------|
| `N8N_HOST` | Hostname para acesso | Domínio (ex: n8n.nooknerd.com.br) |
| `N8N_PORT` | Porta para acesso | Numérico (default: 5678) |
| `N8N_PROTOCOL` | Protocolo para acesso | `http` ou `https` |
| `WEBHOOK_URL` | URL base para webhooks | URL completa (importante para proxy reverso) |
| `N8N_ENDPOINT_WEBHOOK` | Caminho para webhooks | String (default: "webhook") |
| `N8N_ENDPOINT_WEBHOOK_TEST` | Caminho para teste de webhooks | String (default: "webhook-test") |

### Segurança e Criptografia

| Variável | Propósito | Opções |
|----------|-----------|--------|
| `N8N_ENCRYPTION_KEY` | Chave para criptografia | String (deve ser segura e consistente) |
| `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS` | Aplica permissões de arquivo seguras | `true` (recomendado)/`false` |
| `N8N_TRUSTED_PROXIES` | Define proxies confiáveis | `*` para todos ou lista de IPs |
| `N8N_TRUST_PROXY` | Ativa suporte a proxies | `true`/`false` |
| `N8N_SECURE_COOKIE` | Cookies apenas em HTTPS | `true` (recomendado)/`false` |

### Configurações Avançadas

| Variável | Propósito | Opções |
|----------|-----------|--------|
| `N8N_RUNNERS_ENABLED` | Ativa task runners para Code node | `true` (recomendado)/`false` |
| `OFFLOAD_MANUAL_EXECUTIONS_TO_WORKERS` | Processa execuções manuais via workers | `true` (recomendado)/`false` |
| `N8N_METRICS` | Ativa endpoint de métricas | `true`/`false` |
| `N8N_METRICS_INCLUDE_QUEUE_METRICS` | Inclui métricas de fila | `true`/`false` |
| `N8N_DISABLE_PRODUCTION_MAIN_PROCESS` | Desabilita processamento de webhooks no editor | `true`/`false` |
| `N8N_PUSH_BACKEND` | Método de comunicação front/back | `websocket` (recomendado) ou `sse` |
| `GENERIC_TIMEZONE` | Fuso horário do sistema | String (ex: "America/Sao_Paulo") |

## Fluxo de Processamento

1. **Recebimento de Webhook**: 
   - Uma requisição webhook chega ao processador de webhook do n8n
   - O processador valida a requisição e identifica o workflow associado

2. **Enfileiramento**:
   - O webhook processor coloca o ID da execução na fila do Redis
   - Notifica o sistema sobre a nova execução pendente

3. **Processamento**:
   - Um worker disponível pega a execução da fila
   - O worker busca os detalhes do workflow no banco de dados PostgreSQL
   - O worker executa o workflow, realizando todas as operações necessárias

4. **Finalização**:
   - O worker salva os resultados da execução no PostgreSQL
   - Notifica o sistema sobre a conclusão da execução
   - O Redis atualiza o status da execução

## Escalabilidade

Esta arquitetura permite várias estratégias de escalabilidade:

1. **Escalabilidade Vertical**:
   - Aumente `QUEUE_WORKER_CONCURRENCY` para processar mais workflows por worker
   - Aumente recursos (CPU/memória) dos contêineres

2. **Escalabilidade Horizontal**:
   - Adicione mais workers e webhook processors clonando os serviços no docker-compose
   - O Traefik distribuirá automaticamente o tráfego

3. **Otimização de Recursos**:
   - Configure `N8N_DISABLE_PRODUCTION_MAIN_PROCESS=true` para dedicar o editor apenas à interface
   - Ative `OFFLOAD_MANUAL_EXECUTIONS_TO_WORKERS=true` para descarregar o editor

## Considerações de Performance

- **Banco de Dados**: Configure índices adequados e monitoramento de performance
- **Redis**: Em ambientes de alta carga, considere usar um cluster Redis
- **Network**: Garanta baixa latência entre todos os componentes
- **Logs**: Ajuste `N8N_LOG_LEVEL` para encontrar o equilíbrio entre debugging e performance

## Troubleshooting

### Problemas de Conexão Redis
- Verifique se o Redis está acessível na rede interna
- Confirme se as portas estão abertas corretamente
- Valide as credenciais de acesso

### Erros de Webhook
- Verifique a configuração `WEBHOOK_URL` para garantir que os webhooks estão registrados com URL correta
- Confirme as regras de proxy reverso no Traefik

### Problemas de Chave de Criptografia
- Garanta que `N8N_ENCRYPTION_KEY` é consistente em todos os contêineres
- Se mudar a chave, credenciais existentes ficarão inacessíveis

### Conexão com Banco de Dados
- Verifique se PostgreSQL está disponível e healthy
- Confirme se os scripts de inicialização executaram corretamente

## Monitoramento

Com a configuração `N8N_METRICS=true`, o n8n expõe um endpoint `/metrics` com métricas Prometheus que incluem:
- Performance de execução de workflows
- Utilização de filas
- Status de saúde do sistema
- Métricas de nós e execuções

Recomenda-se configurar um sistema de monitoramento como Prometheus + Grafana para visualizar estas métricas.