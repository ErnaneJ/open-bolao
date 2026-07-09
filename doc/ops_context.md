# OPS Context — Copa do Mundo FIFA 2026

Registro de incidentes, decisões e comportamentos conhecidos da API para referência futura.

---

## TSDB API — Comportamentos Conhecidos

### Round numbers para FIFA WC 2026 (league_id: 4429, season: 2026)

| Fase | intRound no TSDB | Jogos |
|------|-----------------|-------|
| Fase de Grupos | 1, 2, 3 | 72 jogos |
| Rodada de 32 | 32 | 16 jogos |
| Oitavas de Final | 16 | 8 jogos |
| **Quartas de Final** | **125** | **4 jogos** |
| Semi-final | — | — (ainda não lançado) |
| Final | — | — (ainda não lançado) |

> ⚠️ O round 125 (Quartas) foi descoberto via `eventsnextleague.php` e `eventspastleague.php`.
> O `KNOCKOUT_SUPPLEMENT_ROUNDS = [32, 16, 8, 4]` NÃO captura o round 125.
> Para fases futuras, usar `fetch_next_matches` / `fetch_last_matches` para descobrir o round number correto, depois fetchá-lo via `eventsround.php`.

### Status strings da TSDB API

| strStatus | Significado | Nosso status |
|-----------|-------------|--------------|
| `FT` | Full Time | finished |
| `AET` | After Extra Time | finished |
| `PEN` | After Penalties | finished |
| `AP` | After Penalties (variante) | finished ← **fix deployado 2026-07-09** |
| `1H`, `2H`, `HT`, `LIVE`, `ET` | Em andamento | live |
| `NS` | Not Started | scheduled |
| `PPD` | Adiado | postponed |
| `CANC` | Cancelado | cancelled |

> `AP` retornado para jogos decididos por pênaltis não estava mapeado, causando status=scheduled mesmo com placar preenchido.
> Fix: `app/adapters/api_providers/thesportsdb_adapter.rb` — commit `8ce4ad0`.

### Limite do endpoint `eventsseason.php`

Com a chave `123` (PAID_KEY), o endpoint retorna **apenas 15 eventos** (os mais recentes).
Não usar como fonte principal de sincronização — jogos mais antigos nunca serão retornados.
`FetchResultsJob` usa este endpoint e por isso não atualiza jogos encerrados há mais de ~2 semanas.

---

## Incidente 2026-07-09 — Duplicatas e Jogos Sumidos

### Causa raiz

O banco tinha **dois registros para cada jogo da fase de grupos**:
- **Registro seed** (worldcup26.ir): `external_id` = números sequenciais (1, 2, 3...), `external_provider_name = nil`, `external_tsdb_id = nil`
- **Registro TSDB**: `external_id` = ID real do TSDB, `external_provider_name = 'thesportsdb'`

Os registros seed tinham `status=scheduled` permanentemente (nenhum provider os atualizava), aparecendo como "Próximos" no bolão mesmo para jogos encerrados.

### O que foi feito

```sql
-- 54 jogos seed deletados (com contraparte TSDB)
-- 71 pool_matches duplicados removidos
-- 30 jogos seed sem contraparte mantidos (mas sincronizados aos bolões)
-- 4 jogos do round 125 atualizados via seed → TSDB
```

Script de limpeza (rodado via `docker compose exec web bin/rails runner`):
1. Para cada jogo seed, busca contraparte TSDB por `(home_team_id, away_team_id, DATE(scheduled_at))`
2. Migra tips para o registro TSDB (ou descarta se já existia tip no TSDB)
3. Remove pool_matches do seed, deleta o registro seed
4. Remove pool_matches duplicados (mesmo `pool_id + match_id`)
5. Sincroniza jogos órfãos (sem TSDB) para todos os bolões do torneio

### Jogos com status "AP" corrigidos manualmente

Jogos decididos por pênaltis que ficaram como `scheduled`:

| Jogo | TSDB ID | Placar |
|------|---------|--------|
| Germany × Paraguay | 2502846 | 1-1 |
| Netherlands × Morocco | 2499836 | 1-1 |
| Australia × Egypt | 2502848 | 1-1 |
| Switzerland × Colombia | 2513671 | 0-0 |

Corrigidos via `Match.find_by(external_tsdb_id: ...).update!(status: :finished, ...)`.
Após deploy do fix `8ce4ad0`, o `FetchResultsJob` passa a mapeá-los corretamente.

### Quartas de final (round 125) atualizadas nos seeds

Os 4 jogos do round 125 existiam como seeds com horários errados (worldcup26.ir timezone incorreto).
Foram atualizados com dados do TSDB:

| Jogo | TSDB ID | Horário correto (BRT) |
|------|---------|----------------------|
| France × Morocco | 2515305 | 09/Jul 17:00 |
| Spain × Belgium | 2519345 | 10/Jul 16:00 |
| Norway × England | 2517651 | 11/Jul 18:00 |
| Argentina × Switzerland | 2520608 | 11/Jul 22:00 |

---

## Pendências

- [ ] Adicionar `125` ao `KNOCKOUT_SUPPLEMENT_ROUNDS` no `ImportTournamentMatchesJob` e `ThesportsdbAdapter`
- [ ] Descobrir o round number das semi-finais e final quando o TSDB lançar esses dados
- [ ] `FetchResultsJob` não atualiza jogos fora da janela de 15 do `eventsseason.php` — considerar usar `eventsround.php` por round para sincronização mais completa
- [ ] 30 jogos órfãos (sem tsdb_id) do seed worldcup26.ir ainda estão no banco — remover quando/se o TSDB tiver os mesmos dados

---

## Produção

- **Servidor:** CasaOS em `casaos` via SSH
- **Path:** `/home/casaos/apps/open-bolao`
- **Stack:** Docker Compose (web + sidekiq + db + redis)
- **Deploy:** `git pull && docker compose build web sidekiq && docker compose up -d web sidekiq`
- **Rails runner:** `docker compose exec web bin/rails runner "..."`
- **Logs:** `docker logs open-bolao-web-1` / `docker logs open-bolao-sidekiq-1`

## Bolões ativos

| Nome | ID | Invite Code |
|------|----|-------------|
| Ernane & Martha - Copa do Mundo FIFA 2026 | 5 | `APVYDE3S` |
| Bolão da TI da Real - Copa do Mundo FIFA 2026 | 1 | `QMRU58YS` |
| RESENHA DAS BET | 7 | `FDXDH5AB` |
