# 08 - Testes QA gates

## Objetivo
- Dono sugerido: `Agente iOS QA`.
- Definir e executar gates de qualidade para impedir regressao funcional da V1.

## Escopo
- Entregaveis:
  - Matriz de testes unitarios por modulo novo.
  - Cenarios de integracao de sync/submissao.
  - Roteiro de smoke real em dispositivo.
  - Comandos padrao de validacao e criterios de bloqueio de merge.

## Fora de escopo
- Testes E2E com infraestrutura externa dedicada.
- Monitoracao de producao (fica para pos-release).

## Pre-requisitos
- Passos `01` a `07` em andamento (este passo roda de forma evolutiva).
- Ambiente de simulador iPhone 17 disponivel.

## Arquivos iOS impactados
- `ios/LigaRun/Tests/LigaRunTests/*`
- `ios/LigaRun/scripts/run-tests.sh`
- `ios/LigaRun/README.md` (se ajustar comando/documentacao)
- `ios/docs/gds-v1-ios/*.md` (rastreabilidade de cenarios)

## Tarefas detalhadas
1. Criar casos unitarios para `HealthKitRunSyncProviding` e coordinator.
2. Criar testes para estados do `CompanionSyncState`.
3. Criar testes para `MapViewModel` em refresh de tile.
4. Criar testes para `BandeirasViewModel` (create/join/leave).
5. Criar testes para resumo de resultado e mapeamento de reasons.
6. Executar validacao padrao:
   - `cd ios/LigaRun && xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17" test`
7. Definir bloqueios de merge:
   - testes falhando;
   - criterio GDS nao atendido;
   - fluxo principal sem smoke real.

## Criterios de pronto
1. Cobertura adicionada para todos os modulos novos da V1.
2. Suite principal passa no simulador padrao.
3. Smoke real executado e registrado.
4. Todos os 6 casos de aceite abaixo mapeados e validados.

## Plano de testes
1. Caso 1: corrida valida sincroniza e gera acao territorial.
2. Caso 2: corrida invalida salva sem efeito competitivo.
3. Caso 3: falha de rede preserva sessao para retry.
4. Caso 4: permissoes negadas exibem fallback correto.
5. Caso 5: entrada em bandeira altera destino das acoes futuras.
6. Caso 6: mapa reflete estado do tile apos resultado.

## Riscos
- Dependencia de dados reais para validar cenarios territoriais especificos.
- Fragilidade de testes com componentes assincronos de HealthKit.

## Handoff para proximo passo
- Entregar relatorio final de QA para `09-hardening-release.md`.
- Abrir bugs bloqueantes antes de iniciar fase final de release.

## Entrega executada (2026-02-06)

### Matriz de testes unitarios por modulo (V1)
| Modulo | Cobertura adicionada | Arquivo de teste |
|---|---|---|
| Sync/submissao + retry local | upload de pendencias, conversao payload, falha preserva retry | `ios/LigaRun/Tests/LigaRunTests/RunUploadServiceTests.swift` |
| Companion estados | start/pause/resume/stop + progress por localizacao | `ios/LigaRun/Tests/LigaRunTests/CompanionRunManagerTests.swift` |
| Mapa refresh/foco | `loadTiles`, `refreshDisputed`, `focusOnTile`, erro de refresh | `ios/LigaRun/Tests/LigaRunTests/MapViewModelTests.swift` |
| Bandeiras | `create`, `join`, `leave`, erro de `join` | `ios/LigaRun/Tests/LigaRunTests/BandeirasViewModelTests.swift` |
| Resultado pos-corrida | traducao de reasons + prioridade de `tileFocusId` | `ios/LigaRun/Tests/LigaRunTests/SubmissionResultPresentationTests.swift` |

### Casos de aceite do plano de testes (1-6)
1. Corrida valida sincroniza e gera acao territorial:
   - Validado em `RunUploadServiceTests.testUploadPendingSessionsUploadsPendingAndSkipsUploaded`.
2. Corrida invalida salva sem efeito competitivo:
   - Validado em `SubmissionResultPresentationTests` (reasons e fallback textual).
3. Falha de rede preserva sessao para retry:
   - Validado em `RunUploadServiceTests.testUploadMarksFailedAndPreservesSessionForRetryOnNetworkError`.
4. Permissoes negadas exibem fallback correto:
   - Validado em `HealthKitAuthorizationStoreTests`.
5. Entrada em bandeira altera destino das acoes futuras:
   - Validado em `BandeirasViewModelTests` (`join`/`leave` com refresh de usuario).
6. Mapa reflete estado do tile apos resultado:
   - Validado em `MapViewModelTests` + `SubmissionResultPresentationTests` (`tileFocusId`).

### Gate de merge (definido)
- Bloquear merge se:
  - `xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17" test` falhar;
  - qualquer caso de aceite 1-6 ficar sem cobertura/validacao;
  - smoke real em dispositivo nao for executado/registrado.

### Comando padrao de validacao
- `cd ios/LigaRun && xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17" test`
