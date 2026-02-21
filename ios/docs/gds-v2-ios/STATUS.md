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
- `01` Contrato e Modelos Quadra - Status: Todo.
- `02` Mapa Quadras (Render + Interacao) - Status: Todo.
- `03` Elegibilidade Local (Campeao ou Dono) - Status: Todo.
- `04` Companion HUD (Modo Competitivo vs Treino) - Status: Todo.
- `05` Pipeline Sync/Upload com Modo - Status: Todo.
- `06` Resultado Pos-corrida e Foco em Quadra - Status: Todo.
- `07` Refactor e Limpeza de Legado Tile - Status: Todo.
- `08` Testes, QA e Gates de Merge (V2 Quadras) - Status: Todo.
- `09` Hardening e Release Readiness (V2 Quadras) - Status: Todo.

- `03` 2026-02-21 - Status: In Progress.
  Resumo tecnico: inicio da implementacao da politica local de elegibilidade campeao/dono com status competitivo vs treino e razoes padronizadas.
  Branch/worktree: `work` em `/workspace/runwarapp`.
  Testes: pendente.

- `03` 2026-02-21 - Status: Blocked.
  Resumo tecnico: politica `QuadraEligibilityPolicy` implementada com reasons padronizadas, helper de consulta (`canCompete`) e suite dedicada de testes unitarios cobrindo cenarios de dono, campeao e inelegibilidade.
  Branch/worktree: `work` em `/workspace/runwarapp`.
  Testes: `cd ios/LigaRun && xcodegen generate` (falhou: `xcodegen` indisponivel no ambiente), `cd ios/LigaRun && xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 15" -only-testing:LigaRunTests/QuadraEligibilityPolicyTests test` (falhou: `xcodebuild` indisponivel no ambiente).
