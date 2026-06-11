<div align="center">

# ⚽ Open Bolão

**Plataforma self-hosted de bolão de futebol — multi-torneio, tempo real e com webhooks.**

[![Ruby](https://img.shields.io/badge/Ruby-4.0-CC342D?style=flat-square&logo=ruby&logoColor=white)](https://ruby-lang.org)
[![Rails](https://img.shields.io/badge/Rails-8.1-CC0000?style=flat-square&logo=rubyonrails&logoColor=white)](https://rubyonrails.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791?style=flat-square&logo=postgresql&logoColor=white)](https://postgresql.org)
[![Redis](https://img.shields.io/badge/Redis-7-DC382D?style=flat-square&logo=redis&logoColor=white)](https://redis.io)
[![License](https://img.shields.io/badge/Licença-MIT-green?style=flat-square)](LICENSE)

[Funcionalidades](#-funcionalidades) · [Deploy rápido](#-deploy-com-docker) · [Setup local](#-desenvolvimento-local) · [Webhooks](#-webhooks) · [Contribuir](#-contribuindo)

</div>

---

## O que é

Open Bolão é uma aplicação Rails completa para gerenciar bolões de futebol. Você hospeda no seu próprio servidor (um Raspberry Pi, um VPS, um CasaOS em casa) e tem controle total sobre os dados.

- Sincroniza resultados automaticamente via **TheSportsDB** ou **API Copa 2026**
- Atualiza placares e rankings em **tempo real** com ActionCable
- Dispara **webhooks** para integrar com Discord, Telegram, Zapier ou qualquer serviço externo
- Suporta múltiplos torneios e admins em paralelo

---

## ✨ Funcionalidades

| Área | Detalhe |
|---|---|
| **Bolões** | Torneio completo ou jogo único, código de convite, visibilidade pública/privada |
| **Palpites** | Lock automático antes do jogo, privacidade configurável por pool |
| **Pontuação** | Placar exato, acerto de vencedor, empate — totalmente configurável por bolão |
| **Ranking** | Tempo real via ActionCable, tendência de posição (subiu/desceu), dense ranking |
| **Sincronização** | Polling automático via SyncSchedule, importação de times e partidas por temporada |
| **Webhooks** | 7 eventos (`match.goal`, `match.live`, `match.finished`, `pool.ranking_updated`, `pool.finished`, `tip.scored`, `pool.daily_matches`), HMAC-SHA256, retry com backoff |
| **Notificações** | Push em tempo real para gols, início e fim de partida, ranking atualizado |
| **Admin** | Painel por bolão: partidas, participants, lineup, webhook endpoints |
| **Super Admin** | Torneios, times, stages, sync schedules, providers, Sidekiq, Blazer |
| **Auth** | Devise + Pundit, 3 roles: `user`, `admin`, `super_admin` |

---

## 🚀 Deploy com Docker

A forma mais rápida de subir em qualquer servidor (CasaOS, VPS, Raspberry Pi).

### 1. Clone e configure

```bash
git clone https://github.com/ErnaneJ/open-bolao.git
cd open-bolao
cp .env.example .env
```

Edite o `.env`:

```env
# Obrigatório
POSTGRES_PASSWORD=senha_forte_aqui
SECRET_KEY_BASE=   # gere com: docker run --rm ruby:4.0.5-slim ruby -e "require 'securerandom'; puts SecureRandom.hex(64)"
APP_HOST=192.168.1.10:39217   # IP do seu servidor na rede

# Super admin criado no primeiro boot
SEED_ADMIN_EMAIL=admin@bolao.local
SEED_ADMIN_PASSWORD=troque_esta_senha!
```

### 2. Suba

```bash
docker compose up -d --build
```

O container `web` executa `db:prepare` + `db:seed` automaticamente na primeira inicialização. Acompanhe com `docker compose logs -f web`.

### 3. Acesse

```
http://SEU_IP:39217
```

Login: `SEED_ADMIN_EMAIL` / `SEED_ADMIN_PASSWORD`

### Atualizar

```bash
git pull && docker compose up -d --build
```

Migrações rodam automaticamente.

---

## 💻 Desenvolvimento local

### Pré-requisitos

- Ruby 4.0+ (recomendado via [mise](https://mise.jdx.dev) ou [rbenv](https://github.com/rbenv/rbenv))
- PostgreSQL 16
- Redis 7
- ImageMagick (`brew install imagemagick`)

### Setup

```bash
git clone https://github.com/ErnaneJ/open-bolao.git
cd open-bolao

cp .env.example .env
# Ajuste DATABASE_URL e REDIS_URL para apontar para seu banco local

bundle install
bin/rails db:create db:migrate db:seed
bin/dev
```

Acesse `http://localhost:3000` — login: `admin@bolao.local` / `changeme123!`

### Rodar os jobs em background

Em outro terminal:

```bash
bundle exec sidekiq
```

> Sem o Sidekiq rodando, sincronizações, webhooks e rankings não funcionam.

---

## ⚙️ Variáveis de ambiente

| Variável | Descrição | Obrigatória |
|---|---|:---:|
| `DATABASE_URL` | URL completa do PostgreSQL | ✅ |
| `REDIS_URL` | URL do Redis | ✅ |
| `SECRET_KEY_BASE` | Chave secreta Rails (64+ chars hex) | ✅ |
| `APP_HOST` | Host público — usado em links de e-mail | ✅ |
| `POSTGRES_PASSWORD` | Senha do PostgreSQL (apenas Docker) | ✅ |
| `APP_PORT` | Porta exposta no host (default `39217`) | — |
| `SEED_ADMIN_EMAIL` | E-mail do super admin inicial | — |
| `SEED_ADMIN_PASSWORD` | Senha do super admin inicial | — |
| `RAILS_LOG_LEVEL` | Nível de log: `debug`, `info`, `warn` | — |
| `SMTP_ADDRESS` | Servidor SMTP para envio de e-mails | — |
| `SMTP_USER` / `SMTP_PASSWORD` | Credenciais SMTP | — |

---

## 🔗 Webhooks

Registre endpoints em **Admin → Webhook Endpoints** e escolha quais eventos receber.

### Eventos disponíveis

| Evento | Descrição |
|---|---|
| `match.goal` | Gol marcado (inclui placar atual) |
| `match.live` | Partida iniciou |
| `match.finished` | Partida encerrada com placar final |
| `pool.ranking_updated` | Ranking do bolão foi recalculado |
| `pool.finished` | Bolão encerrado (todos os jogos terminaram) |
| `tip.scored` | Palpite de um participante foi pontuado |
| `pool.daily_matches` | Resumo diário dos jogos do dia (8h BRT) |

### Segurança

Cada entrega inclui o header `X-Bolao-Signature: sha256=<hmac>`. Valide no seu endpoint:

```ruby
expected = OpenSSL::HMAC.hexdigest("SHA256", seu_secret, request.body.read)
ActiveSupport::SecurityUtils.secure_compare("sha256=#{expected}", request.headers["X-Bolao-Signature"])
```

### Retentativas

Falhas são reprocessadas automaticamente em `1min → 5min → 15min` (3 tentativas no total).

---

## 🏗️ Arquitetura

```
web (Puma)          → Rails 8.1, Hotwire, Tailwind CSS 4
sidekiq             → jobs de sync, webhooks, rankings, notificações
postgres            → dados principais
redis               → cache, ActionCable (tempo real), Sidekiq
```

### Jobs agendados

| Job | Frequência | Função |
|---|---|---|
| `Sync::SchedulerJob` | a cada minuto | Dispara fetch de resultados para schedules ativos |
| `Pools::LockTipsJob` | a cada minuto | Bloqueia palpites antes do início das partidas |
| `Sync::DailyRefreshJob` | 6h UTC | Importa partidas e times de torneios ativos |
| `Webhooks::DailyMatchesNotificationJob` | 11h UTC (8h BRT) | Envia resumo diário de jogos |
| `Sync::PurgeLogsJob` | domingo 3h UTC | Limpa logs antigos de sincronização |

### Roles

| Role | O que pode fazer |
|---|---|
| `user` | Entrar em bolões, fazer palpites, ver ranking e detalhes de partidas |
| `admin` | Criar e gerenciar bolões, inserir resultados manuais, configurar webhooks |
| `super_admin` | Acesso total + torneios, providers, sync schedules, Sidekiq UI, Blazer |

---

## 🧪 Testes

```bash
bundle exec rspec              # suíte completa
bundle exec rspec spec/models  # apenas models
bundle exec rubocop            # lint
bundle exec brakeman           # segurança
```

> Antes de rodar os specs pela primeira vez: `bin/rails db:migrate RAILS_ENV=test`

---

## 📡 Sincronização de resultados

1. Acesse `/super_admin/api_providers` e cadastre um provider (TheSportsDB com sua API key)
2. Vá em `/super_admin/tournaments`, crie ou importe um torneio
3. Na aba **Sincronização** do torneio, ative o schedule e defina o intervalo (mínimo 300s)
4. O `Sync::SchedulerJob` passa a fazer polling automático durante a janela ativa

Use o botão **"Forçar sync agora"** no painel para testar manualmente.

---

## 🤝 Contribuindo

Pull requests são bem-vindos. Para mudanças grandes, abra uma issue primeiro.

```bash
git checkout -b feat/minha-feature
# faça as mudanças
bundle exec rspec && bundle exec rubocop
git commit -m "feat: descrição clara da mudança"
git push origin feat/minha-feature
```

Commits seguem [Conventional Commits](https://www.conventionalcommits.org): `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, `test:`.

---

## 📄 Licença

MIT © [Ernane Ferreira](https://github.com/ErnaneJ)
