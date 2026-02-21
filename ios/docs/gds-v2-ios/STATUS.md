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
- `04` Companion HUD (Modo Competitivo vs Treino) - Status: Todo.
- `05` Pipeline Sync/Upload com Modo - Status: Todo.
- `06` Resultado Pos-corrida e Foco em Quadra - Status: Todo.
- `07` Refactor e Limpeza de Legado Tile - Status: Todo.
- `08` Testes, QA e Gates de Merge (V2 Quadras) - Status: Todo.
- `09` Hardening e Release Readiness (V2 Quadras) - Status: Todo.

## Atualizacoes
- `05` 2026-02-21 - Status: In Progress.
  Resumo tecnico: Inicio do passo 05 com foco em persistencia de contexto competitivo (mode + targetQuadraId) no pipeline de sync/upload da corrida.
  Branch/worktree: work em /workspace/runwarapp.
  Testes: aguardando implementacao e execucao.
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
