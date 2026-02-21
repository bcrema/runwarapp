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
  Resumo tecnico: Contratos MapAPI/RunSubmission migrados para quadras; modelos centrais atualizados (Quadra/QuadraStats, campos targetQuadraId/quadrasCovered/primaryQuadra/quadraId com decode retrocompativel); APIClient apontando para /api/quadras; TileService renomeado para QuadraService; fixtures e testes ajustados para novo dominio.
  Branch/worktree: feature/ios-quadra-step01 em /workspace/runwarapp.
  Testes: xcodegen generate (falhou: comando inexistente no ambiente), xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17,OS=26.2" -only-testing:LigaRunTests/MapViewModelTests test (falhou: comando inexistente no ambiente).

- `01` 2026-02-21 - Status: In Progress.
  Resumo tecnico: Inicio da migracao de contratos/modelos/API client de tile para quadra, incluindo assinatura de protocolos e fixtures base.
  Branch/worktree: feature/ios-quadra-step01 em /workspace/runwarapp.
  Testes: ainda nao executados (em andamento).

- `01` Contrato e Modelos Quadra - Status: Done.
- `02` Mapa Quadras (Render + Interacao) - Status: Todo.
- `03` Elegibilidade Local (Campeao ou Dono) - Status: Todo.
- `04` Companion HUD (Modo Competitivo vs Treino) - Status: Todo.
- `05` Pipeline Sync/Upload com Modo - Status: Todo.
- `06` Resultado Pos-corrida e Foco em Quadra - Status: Todo.
- `07` Refactor e Limpeza de Legado Tile - Status: Todo.
- `08` Testes, QA e Gates de Merge (V2 Quadras) - Status: Todo.
- `09` Hardening e Release Readiness (V2 Quadras) - Status: Todo.

