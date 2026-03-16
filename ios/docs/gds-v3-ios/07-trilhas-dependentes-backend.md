# 07 - Trilhas Dependentes de Backend

## Issue canonica
`GDS v3 iOS / 07 - Trilhas dependentes de backend`

## Objetivo
- Dono sugerido: `Agente iOS Backend Dependency Track`.
- Isolar o backlog que dependia de backend novo para nao contaminar a wave principal.
- Definir criterios objetivos de destravamento e encerrar a trilha assim que o backend real existisse.

## Subagentes
- `07A` Ranking solo.
- `07B` Presenca semanal da bandeira.
- `07C` Notificacoes e inbox.
- `07D` Badges e missoes.

## Status em 2026-03-16
- `Done` para o escopo desta issue.
- O motivo original do bloqueio foi resolvido pela `#90`, mergeada no PR `#92`.
- A issue nao precisa mais permanecer `Blocked`: os contratos minimos existem no backend real, aparecem no OpenAPI exportado e possuem cobertura automatizada.

## Historico do bloqueio
- Estado inicial: `Blocked` por ausencia de contrato backend dedicado.
- Esta issue existiu para manter explicito que a wave principal nao deveria mockar nem absorver no app contratos ainda inexistentes.
- O backlog foi corretamente isolado ate a entrega do backend correspondente.

## Base verificada no backend em 2026-03-16
- Referencias consultadas:
  - `backend/openapi/openapi.json`
  - `backend/README.md`
  - `backend/src/main/kotlin/com/runwar/domain/user/UserController.kt`
  - `backend/src/main/kotlin/com/runwar/domain/bandeira/BandeiraController.kt`
  - `backend/src/main/kotlin/com/runwar/notification/NotificationController.kt`
  - `backend/src/test/kotlin/com/runwar/domain/user/UserControllerTest.kt`
  - `backend/src/test/kotlin/com/runwar/domain/user/UserContractsServiceTest.kt`
  - `backend/src/test/kotlin/com/runwar/domain/bandeira/BandeiraControllerTest.kt`
  - `backend/src/test/kotlin/com/runwar/domain/bandeira/BandeiraPresenceServiceTest.kt`
  - `backend/src/test/kotlin/com/runwar/notification/NotificationControllerTest.kt`
  - `backend/src/test/kotlin/com/runwar/notification/NotificationContractsServiceTest.kt`
- Contratos agora disponiveis:
  - `GET /api/users/rankings?scope=season`
  - `GET /api/bandeiras/{id}/presence?period=week`
  - `GET /api/notifications?cursor=<opaque>&limit=20`
  - `POST /api/devices/push-token`
  - `GET /api/users/me/badges`
  - `GET /api/users/me/missions/active`
- Regras/documentacao confirmadas:
  - presenca semanal documentada com timezone `America/Sao_Paulo` e janela de segunda `00:00` a domingo `23:59:59.999`
  - `members[]` da presenca inclui membros sem atividade com `presenceState=INACTIVE`
  - registro de push token documentado como idempotente por `userId + deviceId`
  - badges retornam `progress` com criterio, valor atual, alvo, unidade e conclusao
  - missoes ativas cobrem progresso parcial e empty state da semana corrente

## Trilhas antes bloqueadas e contrato minimo entregue
1. Ranking solo
   - Entregue em `GET /api/users/rankings?scope=season`.
   - Payload cobre `seasonId`, `seasonName`, `scope`, `generatedAt`, `entries[]` e `currentUserEntry`.
   - Ordenacao e agregacao validadas por teste backend.
2. Presenca semanal da bandeira
   - Entregue em `GET /api/bandeiras/{id}/presence?period=week`.
   - Payload cobre `summary` agregado e `members[]` por usuario.
   - Timezone e janela semanal estao documentados no backend.
3. Notificacoes e inbox
   - Entregue em `GET /api/notifications?cursor=<opaque>&limit=20`.
   - Registro de device entregue em `POST /api/devices/push-token`.
   - Inbox paginada e persistencia idempotente de token estao cobertas por testes backend.
4. Badges e missoes
   - Entregue em `GET /api/users/me/badges`.
   - Entregue em `GET /api/users/me/missions/active`.
   - Contratos cobrem progresso parcial e estado vazio sem calculo adicional no app.

## Criterios de pronto
1. Cada trilha bloqueada teve contrato minimo sugerido e verificado.
2. Cada trilha recebeu criterio objetivo de destravamento e o backend correspondente.
3. O motivo para manter a issue `Blocked` deixou de existir.
4. A issue pode ser encerrada sem bloquear a wave principal.

## Plano de testes
1. Verificar presenca dos endpoints no `backend/openapi/openapi.json`.
2. Verificar controllers e testes backend para cada trilha.
3. Executar `./gradlew test --no-daemon`.

## Dependencias
- Nenhum bloqueio ativo remanescente da trilha 07.
- Evolucoes futuras de UI podem seguir nas issues iOS apropriadas sem reabrir esta trilha de dependencia.

## Handoff
- Registrar comentario final na `#85` indicando que a dependencia foi resolvida pela `#90`/PR `#92`.
- Fechar a `#85`.
- Se surgir novo gap de contrato backend para a wave, abrir issue nova em vez de reusar esta trilha historica.
