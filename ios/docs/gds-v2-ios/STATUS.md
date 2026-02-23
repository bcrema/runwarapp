# STATUS - GDS v2.0 iOS Quadras

## Como usar
1. Registrar toda mudanca de status por passo.
2. Sempre incluir:
   - status
   - resumo tecnico
   - branch/worktree
   - comandos de teste e resultado
3. Nao marcar `Done` sem testes.

## Template de registro
```text
- `<PASSO>` <AAAA-MM-DD> - Status: <In Progress|Blocked|Done>.
  Resumo tecnico: <o que foi feito/bloqueio>.
  Branch/worktree: <branch> em <path>.
  Testes: <comandos executados> (<resultado>).
```

## Backlog inicial
- `01` 2026-02-21 - Status: Done.
  Resumo tecnico: Migracao de contratos/modelos/API de tile para quadra concluida no iOS (MapAPI/RunSubmission, Quadra/QuadraStats, APIClient em /api/quadras, QuadraService e atualizacoes em view models/views), com retrocompatibilidade de decode para chaves legadas e ajustes de fixtures/testes para a nova nomenclatura.
  Branch/worktree: feature/ios-quadra-step01 em /workspace/runwarapp.
  Testes: xcodegen generate (falhou: xcodegen indisponivel no ambiente), xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17,OS=26.2" -only-testing:LigaRunTests/MapViewModelTests test (falhou: xcodebuild indisponivel no ambiente).
- `02` Mapa Quadras (Render + Interacao) - Status: Todo.
- `03` Elegibilidade Local (Campeao ou Dono) - Status: Todo.
- `04` Companion HUD (Modo Competitivo vs Treino) - Status: Done.
- `05` Pipeline Sync/Upload com Modo - Status: Todo.
- `06` Resultado Pos-corrida e Foco em Quadra - Status: Todo.
- `07` Refactor e Limpeza de Legado Tile - Status: Done.
- `08` Testes, QA e Gates de Merge (V2 Quadras) - Status: Todo.
- `09` Hardening e Release Readiness (V2 Quadras) - Status: Todo.

## Atualizacoes
- `09` 2026-02-23 - Status: Blocked.
  Resumo tecnico: Regressao final automatizada concluida e verde apos hardening do fluxo de sincronizacao para preservar contexto de modo ao finalizar corrida (`CompanionRunManager.stopAndSync` agora deriva defaults de `runModeContext`) e alinhamento das suites legadas (`QuadraEligibilityPolicyTests`) para fixtures de `quadra`; varredura de nomenclatura no fluxo alvo (`Features/Map`, `Features/Runs`, `Services`) sem ocorrencias de `tile`.
  Branch/worktree: feature/ios-step09-hardening-release-readiness em /Users/brunocrema/runwarapp.
  Testes: `cd ios/LigaRun && xcodegen generate` (ok); `cd ios/LigaRun && CLANG_MODULE_CACHE_PATH=$(pwd)/ModuleCache SWIFT_MODULE_CACHE_PATH=$(pwd)/ModuleCache SWIFTPM_CACHE_PATH=$(pwd)/.swiftpm/cache xcodebuild -project LigaRun.xcodeproj -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17,OS=26.2" -derivedDataPath $(pwd)/DerivedData -clonedSourcePackagesDirPath /Users/brunocrema/runwarapp/ios/SourcePackages -only-testing:LigaRunTests/QuadraEligibilityPolicyTests test` (8 testes, 0 falhas); `cd ios/LigaRun && CLANG_MODULE_CACHE_PATH=$(pwd)/ModuleCache SWIFT_MODULE_CACHE_PATH=$(pwd)/ModuleCache SWIFTPM_CACHE_PATH=$(pwd)/.swiftpm/cache xcodebuild -project LigaRun.xcodeproj -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17,OS=26.2" -derivedDataPath $(pwd)/DerivedData -clonedSourcePackagesDirPath /Users/brunocrema/runwarapp/ios/SourcePackages -only-testing:LigaRunTests/CompanionRunManagerTests test` (7 testes, 0 falhas); `cd ios/LigaRun && CLANG_MODULE_CACHE_PATH=$(pwd)/ModuleCache SWIFT_MODULE_CACHE_PATH=$(pwd)/ModuleCache SWIFTPM_CACHE_PATH=$(pwd)/.swiftpm/cache xcodebuild -project LigaRun.xcodeproj -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17,OS=26.2" -derivedDataPath $(pwd)/DerivedData -clonedSourcePackagesDirPath /Users/brunocrema/runwarapp/ios/SourcePackages test` (86 testes, 0 falhas); `rg -n "tile|Tile" ios/LigaRun/Sources/LigaRun/Features/Map ios/LigaRun/Sources/LigaRun/Features/Runs ios/LigaRun/Sources/LigaRun/Services` (sem resultados).
  Pendencia para liberar merge/release: smoke manual interativo de mapa/corrida/pos-corrida (tap/foco em quadra, fluxo inelegivel treino e erro de rede com retry) ainda nao evidenciado nesta execucao CLI.
- `09` 2026-02-23 - Status: In Progress.
  Resumo tecnico: Inicio do hardening/release readiness v2 com preparacao do gate final de regressao (testes automatizados completos + smoke manual dirigido em mapa/corrida/pos-corrida), coleta de evidencias e verificacao final de consistencia de nomenclatura.
  Branch/worktree: feature/ios-step09-hardening-release-readiness em /Users/brunocrema/runwarapp.
  Testes: em execucao (planejado: `cd ios/LigaRun && xcodegen generate`, `cd ios/LigaRun && CLANG_MODULE_CACHE_PATH=$(pwd)/ModuleCache SWIFT_MODULE_CACHE_PATH=$(pwd)/ModuleCache SWIFTPM_CACHE_PATH=$(pwd)/.swiftpm/cache xcodebuild -project LigaRun.xcodeproj -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17,OS=26.2" -derivedDataPath $(pwd)/DerivedData -clonedSourcePackagesDirPath /Users/brunocrema/runwarapp/ios/SourcePackages test`).
- `07` 2026-02-22 - Status: Done.
  Resumo tecnico: Limpeza de legado `tile` concluida no fluxo funcional de Mapa + Corrida + Resultado, com remocao de componentes obsoletos sem uso (`StrategicMapView`, `StrategicMapViewModel`, `TileDetailsView`, `TileService`), padronizacao de nomenclatura para `quadra` no fluxo ativo (`MapViewModel`, `ActiveRunHUD`, `QuadraEligibilityPolicy`, `MissionSummaryView`) e retirada de chaves legadas `tile_*` no presentation de resultado.
  Branch/worktree: feature/ios-step07-refactor-legado-tile-wt em /Users/brunocrema/runwarapp/ios/.worktrees/step07-refactor.
  Testes: `cd ios/LigaRun && xcodegen generate` (ok), `cd ios/LigaRun && CLANG_MODULE_CACHE_PATH=$(pwd)/ModuleCache SWIFT_MODULE_CACHE_PATH=$(pwd)/ModuleCache SWIFTPM_CACHE_PATH=$(pwd)/.swiftpm/cache xcodebuild -project LigaRun.xcodeproj -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17,OS=26.2" -derivedDataPath $(pwd)/DerivedData -clonedSourcePackagesDirPath /Users/brunocrema/runwarapp/ios/SourcePackages -disableAutomaticPackageResolution -only-testing:LigaRunTests/MapViewModelTests -only-testing:LigaRunTests/SubmissionResultPresentationTests -only-testing:LigaRunTests/QuadraEligibilityPolicyTests test` (25 testes, 0 falhas).
  Excecoes de legado permitidas: compatibilidade de decode em `ApiModels.swift` mantida para chaves de payload antigo (`targetTileId`, `tilesCovered`, `primaryTile`, `tileId`) e termos de produto fora do fluxo funcional alvo (ex.: Profile/Bandeiras/Auth com "Tiles").
- `07` 2026-02-22 - Status: In Progress.
  Resumo tecnico: Inicio do passo 07 para limpeza de legado `tile` no fluxo funcional (Mapa + Corrida + Resultado), com branch/worktree dedicados para isolamento e varredura textual das referencias residuais.
  Branch/worktree: feature/ios-step07-refactor-legado-tile-wt em /Users/brunocrema/runwarapp/ios/.worktrees/step07-refactor.
  Testes: varredura inicial pendente; suites iOS serao executadas apos os ajustes.
- `06` 2026-02-22 - Status: Done.
  Resumo tecnico: Fluxo pos-corrida consolidado em semantica de quadra no presentation, sem aliases funcionais `tile_*` em reasons; CTA "Ver no mapa" segue foco por `mapFocusQuadraId` com prioridade `turnResult.quadraId` > `territoryResult.quadraId` > `loopValidation.primaryQuadra`. Ajustes de estabilizacao no workspace iOS para viabilizar build/teste (regeneracao do `LigaRun.xcodeproj`, correcoes de compilacao em `ApiModels`/`MapViewModel` e fixtures de teste legadas).
  Branch/worktree: feature/ios-uxflow-step06-quadra-focus em /Users/brunocrema/runwarapp.
  Testes: `cd ios/LigaRun && xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17,OS=26.2" -only-testing:LigaRunTests/SubmissionResultPresentationTests test` (passou: 8 testes, 0 falhas).
- `06` 2026-02-22 - Status: In Progress.
  Resumo tecnico: Retomada do passo 06 para consolidar o fluxo pos-corrida em semantica exclusiva de quadra, validar foco por `quadraId` no CTA "Ver no mapa" e remover referencias funcionais legadas de `tile` no presentation.
  Branch/worktree: feature/ios-uxflow-step06-quadra-focus em /Users/brunocrema/runwarapp.
  Testes: em execucao (`cd ios/LigaRun && xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17,OS=26.2" -only-testing:LigaRunTests/SubmissionResultPresentationTests test`).
- `06` 2026-02-21 - Status: Blocked.
  Resumo tecnico: Fluxo pos-corrida migrado para semantica de quadra no iOS (`submissionQuadraFocusId`, labels/textos em RunsView, `mapFocusQuadraId` em SessionStore/MapScreen) e reason-map atualizado para chaves `quadra_*` com compatibilidade legada para `tile_*`; testes unitarios do presentation ajustados para foco/reasons de quadra.
  Branch/worktree: feature/ios-step06-resultado-quadras em /workspace/runwarapp.
  Testes: `cd ios/LigaRun && xcodegen generate` (falhou: command not found), `cd ios/LigaRun && xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 15" -only-testing:LigaRunTests/SubmissionResultPresentationTests test` (falhou: command not found).
- `08` 2026-02-21 - Status: In Progress.
  Resumo tecnico: Inicio do passo de QA v2 com consolidacao da matriz de suites obrigatorias, sequencia por rodadas e definicao de gate unico de merge.
  Branch/worktree: feature/ios-qa-gates-v2-step08 em /workspace/runwarapp.
  Testes: aguardando execucao das suites obrigatorias e gate final.
- `08` 2026-02-21 - Status: Blocked.
  Resumo tecnico: Matriz QA por passo, sequencia oficial por rodada e checklist de gate de merge foram definidos no documento do passo 08; execucao local das suites ficou bloqueada por ausencia de toolchain Apple (xcodegen/xcodebuild) no ambiente Linux atual.
  Branch/worktree: feature/ios-qa-gates-v2-step08 em /workspace/runwarapp.
  Testes: `cd ios/LigaRun && xcodegen generate` (falhou: command not found), `cd ios/LigaRun && xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17,OS=26.2" -only-testing:LigaRunTests/<SUITE> test` para 7 suites obrigatorias (falhou: command not found), `cd ios/LigaRun && xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17,OS=26.2" test` (falhou: command not found).
- `05` 2026-02-21 - Status: Blocked.
  Resumo tecnico: Persistencia e propagacao de `competitionMode`/`targetQuadraId`/`eligibilityReason` implementadas no RunSessionStore + Coordinator + RunUploadService, com cobertura de testes atualizada para decode legado e payload de upload com fallback TRAINING.
  Branch/worktree: work em /workspace/runwarapp.
  Testes: `cd ios/LigaRun && xcodegen generate` (falhou: command not found), `cd ios/LigaRun && xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 15" test` (falhou: command not found).
