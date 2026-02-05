# 02 - Sync HealthKit pipeline

## Objetivo
- Dono sugerido: `Agente iOS Data/Health`.
- Implementar sincronizacao de corridas do Saude para envio em `/api/runs/coordinates`.

## Escopo
- Entregaveis:
  - Novo protocolo `HealthKitRunSyncProviding`.
  - Novo tipo `SyncedWorkoutPayload` (coordinates, timestamps, source metadata).
  - Servico de leitura de workout + route do HealthKit.
  - Integracao de submissao com fallback de retry local.

## Fora de escopo
- Alterar contrato da API backend.
- Criar pipeline para provedores externos (Strava/Garmin).
- App watchOS nativo.

## Pre-requisitos
- `01-fundacao-permissoes-config.md` concluido.
- Autorizacao de Saude validada no app.

## Arquivos iOS impactados
- `ios/LigaRun/Sources/LigaRun/Services/RunService.swift`
- `ios/LigaRun/Sources/LigaRun/Services/RunUploadService.swift`
- `ios/LigaRun/Sources/LigaRun/Services/RunSessionStore.swift`
- `ios/LigaRun/Sources/LigaRun/Services/HealthKitAuthorizationStore.swift`
- `ios/LigaRun/Sources/LigaRun/Services/` (novo arquivo de sync HealthKit)
- `ios/LigaRun/Tests/LigaRunTests/` (novos testes de servico)

## Tarefas detalhadas
1. Definir `HealthKitRunSyncProviding` e implementar adaptador concreto HealthKit.
2. Definir `SyncedWorkoutPayload` como DTO interno de sincronizacao.
3. Ler workout finalizado no periodo da corrida e buscar `HKWorkoutRoute`.
4. Converter rota em arrays compativeis com `/api/runs/coordinates`.
5. Enviar payload via `RunService.submitRunCoordinates`.
6. Em timeout/erro, persistir sessao pendente no `RunSessionStore` para retry.
7. Registrar observabilidade minima (logs de estado e erro).

## Criterios de pronto
1. Corrida no Fitness/Saude e convertida em payload valido para backend.
2. Timeout de rota nao perde treino: sessao persiste para retry.
3. Falhas de rede mantem sessao como `failed/pending`.
4. Sem quebra de fluxos existentes de upload.

## Plano de testes
1. Unitario: montagem correta de `SyncedWorkoutPayload`.
2. Unitario: timeout de rota ativa fallback de retry.
3. Unitario: erro de rede preserva sessao no store.
4. Integracao (mock API): sucesso retorna `RunSubmissionResult`.
5. Caso mapeado GDS: `Falha de rede preserva sessao para retry local`.
6. Caso mapeado GDS: `Corrida valida sincroniza e gera acao territorial` (com backend real no smoke).

## Riscos
- Latencia do HealthKit para disponibilizar rota apos treino.
- Dados incompletos de timestamp em workouts curtos.
- Complexidade de mocks de HealthKit em testes unitarios.

## Handoff para proximo passo
- Liberar `03-companion-hud-estados.md` e `05-resultado-pos-corrida.md`.
- Documentar contrato interno final de `SyncedWorkoutPayload` no PR.
