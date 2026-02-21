# 07 - Refactor e Limpeza de Legado Tile

## Objetivo
- Dono sugerido: `Agente iOS Refactor`.
- Remover artefatos e referencias obsoletas de `tile` no fluxo funcional alvo, reduzindo ambiguidade de manutencao.

## Escopo
- Entregaveis:
  - Limpeza de arquivos/nomes legados nao utilizados.
  - Atualizacao de servicos e imports residuais.
  - Check final por busca textual de referencias.
- Fora de escopo:
  - Mudancas de regra de negocio.
  - Mudancas de backend.

## Arquivos iOS impactados (candidatos)
- `ios/LigaRun/Sources/LigaRun/Features/Map/StrategicMapViewModel.swift`
- `ios/LigaRun/Sources/LigaRun/Features/StrategicMapView.swift`
- `ios/LigaRun/Sources/LigaRun/Features/Map/TileDetailsView.swift`
- `ios/LigaRun/Sources/LigaRun/Services/TileService.swift` (ja renomeado no passo 01)

## Tarefas detalhadas
1. Validar uso real dos arquivos legados.
2. Remover ou renomear arquivos sem uso no fluxo alvo.
3. Ajustar projeto/targets se remocao impactar compilacao.
4. Executar busca final por termos legados no fluxo funcional:
   - `tile`
   - `mapFocusTileId`
   - `getTiles/getTile/getDisputedTiles`
5. Registrar excecoes de legado permitidas (se houver) no `STATUS.md`.

## Criterios de pronto
1. Nao ha referencia funcional ativa a `tile` em Mapa + Corrida + Resultado.
2. Build iOS sem warnings criticos de simbolos nao usados apos limpeza.
3. Arquitetura de mapa/territorio com nomenclatura consistente.

## Plano de testes
1. Build e testes de regressao do alvo funcional.
2. Validacao textual:
   - `rg -n "mapFocusTileId|getTiles\\(|getTile\\(|getDisputedTiles\\(" ios/LigaRun`
3. Smoke manual de mapa e resultado apos remocoes.

## Dependencias
- Iniciar apos `02` e `06`.

