# 01 - Contrato e Servicos Territorio/Equipe

## Issue canonica
`GDS v3 iOS / 01 - Contrato e servicos territorio/equipe`

## Objetivo
- Dono sugerido: `Agente iOS API/Domain`.
- Preparar o contrato iOS da wave v3 antes da mudanca de navegacao e UI.

## Subagentes
- `01A` Wrappers de API para territorio e equipe.
- `01B` Tipos locais e estado compartilhado da wave.
- `01C` Fixtures, normalizacao de decode e testes.

## Escopo
- Entregaveis:
  - wrappers para `getQuadrasByUser`, `getQuadrasByBandeira` e `updateMemberRole`;
  - tipos locais para filtros de mapa e hub de bandeiras;
  - compatibilidade de decode para `Bandeira` aceitar `totalTiles` e `totalQuadras`.
- Fora de escopo:
  - layout de telas;
  - roteamento entre tabs.

## Arquivos iOS impactados (minimo)
- `ios/LigaRun/Sources/LigaRun/Networking/APIClient.swift`
- `ios/LigaRun/Sources/LigaRun/Models/ApiModels.swift`
- `ios/LigaRun/Sources/LigaRun/App/SessionStore.swift`
- `ios/LigaRun/Tests/LigaRunTests/`

## Tarefas detalhadas
1. Adicionar wrappers no `APIClient` para:
   - `GET /api/quadras/user/{userId}`
   - `GET /api/quadras/bandeira/{bandeiraId}`
   - `PUT /api/bandeiras/{id}/members/role`
2. Introduzir tipos locais:
   - `MapOwnershipFilter`
   - `BandeirasHubTab`
   - request de mutacao de role
3. Normalizar `Bandeira` para aceitar payload atual e legado sem quebrar a UI existente.
4. Expor no `SessionStore` apenas o estado compartilhado canonico da wave, sem ainda amarrar navegacao final.

## Criterios de pronto
1. Contratos necessarios da wave estao disponiveis no iOS.
2. Nenhuma tela nova precisa duplicar chamadas HTTP diretas.
3. Decodes relevantes ficam retrocompativeis onde houver divergencia conhecida.

## Plano de testes
1. Testes unitarios de decode para `Bandeira`.
2. Testes de request payload para mutacao de role.
3. Ajustes de fixtures usados pelos passos `04` e `05`.

## Dependencias
- Pode iniciar imediato.
- Libera `02` e `04`.

## Handoff
- Publicar na issue os nomes finais dos tipos compartilhados para consumo de `02`, `03`, `04`, `05` e `06`.

