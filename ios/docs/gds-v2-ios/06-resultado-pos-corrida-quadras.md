# 06 - Resultado Pos-corrida e Foco em Quadra

## Objetivo
- Dono sugerido: `Agente iOS UX Flow`.
- Migrar fluxo pos-corrida para semantica de quadras com foco no mapa por `quadraId`.

## Escopo
- Entregaveis:
  - Helpers de resultado em nomenclatura `quadra`.
  - `RunsView` com labels/metricas atualizadas.
  - Navegacao "Ver no mapa" usando `mapFocusQuadraId`.
- Fora de escopo:
  - Persistencia de modo no upload (passo 05).
  - Limpeza estrutural de legado (passo 07).

## Arquivos iOS impactados (minimo)
- `ios/LigaRun/Sources/LigaRun/Features/Runs/SubmissionResultPresentation.swift`
- `ios/LigaRun/Sources/LigaRun/Features/Runs/RunsView.swift`
- `ios/LigaRun/Sources/LigaRun/App/SessionStore.swift`
- `ios/LigaRun/Sources/LigaRun/Features/Map/MapScreen.swift`

## Tarefas detalhadas
1. Renomear helper principal:
   - `submissionTileFocusId` -> `submissionQuadraFocusId`
2. Prioridade de foco:
   - `turnResult.quadraId`
   - `territoryResult.quadraId`
   - `loopValidation.primaryQuadra`
3. Atualizar reason-map para chaves `quadra_*`:
   - exemplo: `quadra_in_cooldown`
4. Em `RunsView`:
   - label `Tile foco` -> `Quadra foco`
   - ajustar texto descritivo para quadra.
5. Em session/map:
   - `mapFocusTileId` -> `mapFocusQuadraId`
   - consumir novo campo no `MapScreen`.

## Criterios de pronto
1. Resultado usa somente nomenclatura de quadra.
2. Acao "Ver no mapa" foca corretamente a quadra.
3. Nao restam referencias funcionais a `tile` no fluxo de resultado.

## Plano de testes
1. Atualizar `SubmissionResultPresentationTests`:
   - prioridade de foco por `quadraId`.
   - traducoes `quadra_*`.
2. Smoke manual:
   - completar corrida, abrir resumo, tocar "Ver no mapa".
   - validar foco e detalhe da quadra.

## Dependencias
- Iniciar apos `02` e `05`.
- Pode rodar em paralelo com `07`.

