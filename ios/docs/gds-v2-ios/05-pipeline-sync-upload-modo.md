# 05 - Pipeline Sync/Upload com Modo de Corrida

## Objetivo
- Dono sugerido: `Agente iOS Data/Sync`.
- Persistir e propagar contexto competitivo da corrida ate o payload de upload.

## Escopo
- Entregaveis:
  - `RunSessionRecord` com metadados de modo.
  - `CompanionRunManager`/`RunSyncCoordinator` propagando contexto.
  - `RunUploadService` enviando `mode` e `targetQuadraId`.
- Fora de escopo:
  - Decisao de elegibilidade (passo 03).
  - UX detalhada do HUD (passo 04).

## Arquivos iOS impactados (minimo)
- `ios/LigaRun/Sources/LigaRun/Services/RunSessionStore.swift`
- `ios/LigaRun/Sources/LigaRun/Features/Runs/CompanionRunManager.swift`
- `ios/LigaRun/Sources/LigaRun/Features/Runs/CompanionSyncCoordinator.swift`
- `ios/LigaRun/Sources/LigaRun/Services/RunUploadService.swift`
- `ios/LigaRun/Sources/LigaRun/Networking/APIClient.swift`

## Tarefas detalhadas
1. Adicionar ao `RunSessionRecord`:
   - `competitionMode` (`COMPETITIVE`/`TRAINING`)
   - `targetQuadraId` (`String?`)
   - `eligibilityReason` (`String?`)
2. Garantir backward decode para sessoes antigas sem novos campos.
3. Atualizar `CompanionRunManager.stopAndSync()` para receber contexto final de modo.
4. Atualizar `RunSyncCoordinator.finishRun(...)` para carregar esse contexto.
5. Atualizar `RunUploadService.upload(...)` para enviar no payload:
   - `mode`
   - `targetQuadraId`
6. Garantir fallback seguro:
   - ausencia de contexto => enviar `TRAINING`.

## Criterios de pronto
1. Upload sempre envia `mode` no payload.
2. Corrida inelegivel envia `TRAINING`.
3. Corrida elegivel envia `COMPETITIVE` com alvo quando disponivel.
4. Sessao antiga do store continua decodificando sem quebrar.

## Plano de testes
1. Atualizar `RunSessionStoreTests`:
   - decode de legado sem novos campos.
2. Atualizar `RunSyncCoordinatorTests`:
   - contexto propagado no finish/retry.
3. Atualizar `RunUploadServiceTests`:
   - payload contem `mode`.
   - payload contem `targetQuadraId`.
   - caso inelegivel envia `TRAINING`.

## Dependencias
- Iniciar apos `01` e `03`.
- Pode rodar em paralelo com `04`.

