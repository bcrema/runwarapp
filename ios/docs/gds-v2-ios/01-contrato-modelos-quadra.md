# 01 - Contrato e Modelos Quadra

## Objetivo
- Dono sugerido: `Agente iOS API/Domain`.
- Migrar contratos iOS de `tile` para `quadra` com corte unico, incluindo API client, protocolos, modelos e fixtures base.

## Escopo
- Entregaveis:
  - `MapAPIProviding` em modo quadras.
  - `RunSubmissionAPIProviding` com `mode` e `targetQuadraId`.
  - Modelos renomeados/campos renomeados para quadra.
  - Ajuste de decode/encode para novos campos e enums.
- Fora de escopo:
  - Ajustes visuais de mapa/HUD.
  - Limpeza de legado nao utilizado.

## Arquivos iOS impactados (minimo)
- `ios/LigaRun/Sources/LigaRun/Models/ApiModels.swift`
- `ios/LigaRun/Sources/LigaRun/Networking/APIClient.swift`
- `ios/LigaRun/Sources/LigaRun/Services/TileService.swift` (renomear para `QuadraService`)
- `ios/LigaRun/Tests/LigaRunTests/TestFixtures.swift`

## Tarefas detalhadas
1. Renomear tipos:
   - `Tile` -> `Quadra`
   - `TileStats` -> `QuadraStats`
2. Renomear campos de dominio em resultados:
   - `targetTileId` -> `targetQuadraId`
   - `tilesCovered` -> `quadrasCovered`
   - `primaryTile` -> `primaryQuadra`
   - `primaryTileCoverage` -> `primaryQuadraCoverage`
   - `tileId` -> `quadraId` (turn/territory)
3. Adicionar campos de campeao em `Quadra`:
   - `championUserId`
   - `championBandeiraId`
   - `championName` (opcional, se presente no payload)
4. Atualizar `MapAPIProviding` para:
   - `getQuadras(bounds:)`
   - `getDisputedQuadras()`
   - `getQuadra(id:)`
5. Atualizar `RunSubmissionAPIProviding.submitRunCoordinates(...)` para aceitar:
   - `coordinates`
   - `timestamps`
   - `mode`
   - `targetQuadraId`
6. Ajustar endpoints em `APIClient` para:
   - `GET /api/quadras`
   - `GET /api/quadras/{id}`
   - `GET /api/quadras/disputed`
7. Renomear `TileService` para `QuadraService` (arquivo e classe).
8. Atualizar fixtures para o novo dominio.

## Criterios de pronto
1. Compilacao sem erros de contrato antigo em APIs/modelos centrais.
2. Nao existem chamadas ativas a `getTiles/getTile/getDisputedTiles`.
3. Fixtures atualizadas para suportar os novos tipos/campos.

## Plano de testes
1. `MapViewModelTests` compilando com assinatura nova de `MapAPIProviding`.
2. `RunUploadServiceTests` compilando com assinatura nova de submissao.
3. Execucao parcial recomendada:
   - `xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17,OS=26.2" -only-testing:LigaRunTests/MapViewModelTests test`
   - `xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17,OS=26.2" -only-testing:LigaRunTests/RunUploadServiceTests test`

## Dependencias
- Pode iniciar imediato.
- Libera `04` e `05` quando concluir.

