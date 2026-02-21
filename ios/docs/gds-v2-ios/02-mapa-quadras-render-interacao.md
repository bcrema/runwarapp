# 02 - Mapa Quadras (Render + Interacao)

## Objetivo
- Dono sugerido: `Agente iOS Maps`.
- Migrar o stack de mapa ativo para `quadras` preservando experiencia atual (render, tap, foco, loading e disputas).

## Escopo
- Entregaveis:
  - `MapViewModel` usando `quadras`.
  - `MapScreen` com textos/labels/flow em quadra.
  - `HexMapView` consumindo `Quadra` e source/layers com ids neutros.
- Fora de escopo:
  - Pipeline de upload.
  - Pos-corrida e traducoes de razoes.

## Arquivos iOS impactados (minimo)
- `ios/LigaRun/Sources/LigaRun/Features/Map/MapViewModel.swift`
- `ios/LigaRun/Sources/LigaRun/Features/Map/MapScreen.swift`
- `ios/LigaRun/Sources/LigaRun/Features/Map/HexMapView.swift`

## Tarefas detalhadas
1. Renomear no `MapViewModel`:
   - `tiles` -> `quadras`
   - `selectedTile` -> `selectedQuadra`
   - `tileStateSummary` -> `quadraStateSummary`
2. Renomear metodos:
   - `loadTiles` -> `loadQuadras`
   - `refreshDisputed` -> `refreshDisputedQuadras`
   - `focusOnTile` -> `focusOnQuadra`
3. Em `MapScreen`:
   - atualizar bindings/callbacks para quadra.
   - atualizar textos de loading, disputa e detalhes.
   - atualizar sheet para `QuadraDetailView`.
4. Em `HexMapView`:
   - trocar tipo de dominio de `Tile` para `Quadra`.
   - trocar ids de source/layer para nome neutro (ex.: `territory-source`, `territory-fill`).
5. Manter comportamento funcional:
   - refresh em `onMapIdle`
   - tap seleciona area
   - foco por id vindo de session store (campo novo sera conectado no passo 06)

## Criterios de pronto
1. Mapa carrega e renderiza quadras no viewport.
2. Tap em quadra abre detalhe correto.
3. Estados neutra/dominada/disputa continuam visuais e consistentes.
4. Nenhuma referencia funcional a `tile` no fluxo de mapa.

## Plano de testes
1. Atualizar e executar:
   - `MapViewModelTests`
2. Smoke manual:
   - abrir mapa, mover camera, validar refresh.
   - tocar em quadra e validar sheet.
   - acionar "ver disputas".

## Dependencias
- Pode iniciar imediato.
- Libera `06` e contribui para `07`.

