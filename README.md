# MinIO AIStor — Docker Swarm

Deploy automatizado do [MinIO AIStor](https://min.io/product/aistor) em cluster Docker Swarm com suporte a Traefik reverse proxy e TLS.

## Arquitetura

Este repositório oferece dois modos de execução:

| Modo | Arquivo | Uso |
|------|---------|-----|
| **Docker Compose** | `docker-compose.yaml` | Desenvolvimento e testes locais |
| **Docker Swarm** | `docker-stack.yaml` | Produção com orquestração, Traefik e TLS |

O stack de produção integra-se ao [Traefik](https://traefik.io/) para roteamento automático nas portas:

- **9000** — API S3 (`MINIO_API_HOSTNAME`)
- **9001** — Console Web (`MINIO_SERVER_HOSTNAME`)

## Pré-requisitos

- [Docker Engine](https://docs.docker.com/engine/install/) 20.10+
- [Docker Swarm](https://docs.docker.com/engine/swarm/) inicializado
- Rede externa `swarm-net` criada no cluster
- Licença válida do MinIO AIStor (arquivo `minio/minio.license`)
- Traefik configurado no cluster com rede `swarm-net`
- Certificados TLS (se necessário, em `minio/certs/`)

## Configuração

Copie o template e edite as variáveis de ambiente:

```bash
cp .env.template .env
```

### Variáveis de ambiente

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `MINIO_ROOT_USER` | `minioadmin` | Usuário root do MinIO |
| `MINIO_ROOT_PASSWORD` | `minioadmin` | Senha root do MinIO |
| `MINIO_SERVER_HOSTNAME` | `s3.example.com` | Hostname do console web |
| `MINIO_API_HOSTNAME` | `api.example.com` | Hostname da API S3 |
| `MINIO_NODE_HOSTNAME` | `node-1` | Hostname do nó Swarm para placement |
| `MINIO_SERVER_URL` | `https://api.example.com` | URL pública da API |
| `MINIO_BROWSER_REDIRECT_URL` | `https://s3.example.com` | URL de redirecionamento do console |
| `MINIO_COMPRESSION_ENABLE` | `on` | Habilita compressão de objetos |
| `MINIO_SITE_NAME` | `production-cluster` | Nome do site/cluster |

## Início Rápido

```bash
# 1. Gerar .env a partir do template (valida rede swarm-net)
make setup

# 2. Editar .env com seus valores reais
vim .env

# 3. Validar a configuração
make validate

# 4. Implantar no Swarm
make deploy
```

## Comandos do Makefile

| Comando | Descrição |
|---------|-----------|
| `make help` | Exibe todos os comandos disponíveis |
| `make setup` | Gera `.env` a partir do template e valida a rede Swarm |
| `make deploy` | Implanta o stack MinIO no Swarm |
| `make remove` | Remove o stack MinIO do Swarm |
| `make status` | Mostra o status dos serviços no stack |
| `make logs` | Acompanha os logs do MinIO em tempo real |
| `make pull` | Baixa a imagem mais recente do AIStor |
| `make validate` | Valida a configuração gerada a partir do compose e do `.env` |

## Deploy com Docker Swarm

O `docker-stack.yaml` configura:

- **Replicação:** 1 réplica por padrão
- **Restart policy:** `on-failure` com até 3 tentativas
- **Update strategy:** rollback automático em caso de falha
- **Placement:** restrição por hostname do nó via `MINIO_NODE_HOSTNAME`
- **Secrets:** a licença é injetada via Docker Secrets (`MINIO_LICENSE`)

### Volumes

| Volume | Driver | Uso |
|--------|--------|-----|
| `minio-data` | `local` | Dados dos objetos |
| `minio-certs` | `local` | Certificados TLS |

## Traefik e TLS

O stack utiliza labels do Traefik para roteamento automático:

### Rota da API (porta 9000)

```
Host(`${MINIO_API_HOSTNAME}`) → minio-api → :9000
```

### Rota do Console (porta 9001)

```
Host(`${MINIO_SERVER_HOSTNAME}`) → minio-server → :9001
```

Ambas as rotas utilizam o entrypoint `websecure` com TLS habilitado.

Para configurar certificados TLS, coloque os arquivos em `minio/certs/`:

```
minio/certs/
├── public.crt
└── private.key
```

## Desenvolvimento Local

Para testes locais com Docker Compose (sem Swarm):

```bash
docker compose up -d
```

O MinIO estará disponível em:

- API: `http://localhost:9000`
- Console: `http://localhost:9001`

## Solução de Problemas

| Problema | Solução |
|----------|---------|
| Rede `swarm-net` não encontrada | Criar com `docker network create --driver overlay swarm-net` |
| `.env` não encontrado | Executar `make setup` |
| Falha no deploy | Verificar logs com `make logs` e status com `make status` |
| Erro de licença | Confirmar que `minio/minio.license` existe e é válido |
| Traefik não roteia | Verificar se Traefik está na rede `swarm-net` e se os hostnames resolvem |

## Licença

Este projeto utiliza o [MinIO AIStor](https://min.io/product/aistor), uma solução comercial que requer licença válida. Consulte os termos de uso em [min.io](https://min.io).
