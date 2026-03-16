# 07 - Trilhas Dependentes de Backend

## Issue canonica
`GDS v3 iOS / 07 - Trilhas dependentes de backend`

## Objetivo
- Dono sugerido: `Agente iOS Backend Dependency Track`.
- Separar o backlog que depende de backend novo para nao contaminar a wave principal.

## Subagentes
- `07A` Ranking solo.
- `07B` Presenca semanal da bandeira.
- `07C` Notificacoes e inbox.
- `07D` Badges e missoes.

## Status inicial esperado
- `Blocked` por ausencia de contrato backend dedicado.

## Escopo
- Entregaveis:
  - documentacao do que falta no backend;
  - criterios claros de destravamento;
  - isolamento do backlog nao implementavel nesta wave.
- Fora de escopo:
  - mockar backend ausente no app principal;
  - bloquear a release principal por estas trilhas.

## Trilhas e contratos necessarios
1. Ranking solo:
   - endpoint sugerido `GET /api/users/rankings`
   - payload com posicao, usuario, metricas de temporada e semana.
2. Presenca semanal:
   - endpoint sugerido `GET /api/bandeiras/{id}/presence?period=week`
   - payload com agregacao por membro e total da equipe.
3. Notificacoes:
   - `GET /api/notifications`
   - `POST /api/devices/push-token` ou equivalente.
4. Badges e missoes:
   - endpoints de leitura de badges, progresso e missoes ativas.

## Criterios de pronto
1. Cada trilha bloqueada tem contrato minimo sugerido.
2. Cada trilha tem criterio objetivo de destravamento.
3. A issue permanece explicita como `Blocked` ate o backend existir.

## Plano de testes
1. Nao ha teste funcional obrigatorio enquanto a issue estiver bloqueada.
2. Validar apenas consistencia documental e clareza das dependencias.

## Dependencias
- Pode iniciar imediato.
- Nao bloqueia `09`.

## Handoff
- Manter a issue aberta e bloqueada com comentarios quando houver novidade de contrato backend.

