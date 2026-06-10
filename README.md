# Open Bolão

Sistema de bolão de futebol multi-torneio, self-hosted, com suporte a webhooks, sincronização automática com APIs externas e ranking em tempo real.

## Stack

- **Ruby 4.0 / Rails 8.1** — Hotwire (Turbo + Stimulus), Tailwind CSS 4
- **PostgreSQL 16** — banco de dados principal
- **Redis 7** — cache, ActionCable, Sidekiq
- **Sidekiq 7** — jobs em background e sincronização de resultados
- **Blazer** — analytics em `/super_admin/blazer`
- **Devise + Pundit** — autenticação e autorização por roles

## Setup local (desenvolvimento)

### Pré-requisitos

- Ruby 4.0+, Rails 8.1+
- PostgreSQL 16
- Redis 7
- Node.js 20+

### Passos

```bash
git clone <seu-repositório>
cd open-bolao

cp .env.example .env
# Edite .env com suas configurações locais

bundle install
bin/rails db:create db:migrate db:seed
bin/dev
```

Acesse: `http://localhost:3000`

Login inicial: `admin@bolao.local` / `changeme123!`

## Variáveis de ambiente

| Variável | Descrição | Produção |
|---|---|---|
| `DATABASE_URL` | URL completa do PostgreSQL | Obrigatório |
| `REDIS_URL` | URL do Redis | Obrigatório |
| `SECRET_KEY_BASE` | Chave secreta Rails | Obrigatório |
| `SEED_ADMIN_EMAIL` | E-mail do super admin inicial | Recomendado |
| `SEED_ADMIN_PASSWORD` | Senha do super admin inicial | Recomendado |
| `APP_HOST` | Host da aplicação | Para mailers |
| `SMTP_ADDRESS` / `SMTP_USER` / `SMTP_PASSWORD` | Credenciais SMTP | Para e-mails |

## Deploy com Docker (CasaOS / VPS)

```bash
cp .env.example .env
# Configure: POSTGRES_PASSWORD, SECRET_KEY_BASE, SEED_ADMIN_EMAIL, etc.

docker compose up -d --build
```

O contêiner `app` roda `db:prepare` + `db:seed` automaticamente na primeira inicialização.

## Como criar um bolão

1. Login como admin → `/admin/pools/new`
2. Escolha o escopo: **Bolão de Torneio** ou **Bolão de Jogo Único**
3. Configure regras de pontuação
4. Compartilhe o link ou código de convite

## Configurando sincronização automática

1. `/super_admin/api_providers` → cadastre um provedor (ex: Worldcup 2026)
2. Torneio → aba Sincronização → ative o schedule e defina o intervalo
3. Use "Forçar sync agora" para testar

## Papéis

| Role | Acesso |
|---|---|
| `user` | Entra em bolões, faz palpites, vê ranking |
| `admin` | Cria e gerencia bolões, insere resultados |
| `super_admin` | Acesso total, Blazer, Sidekiq |

## Testes

```bash
bundle exec rspec
```

## Licença

MIT
