# 04 - Mapa home CTA tiles

## Objetivo
- Dono sugerido: `Agente iOS Maps`.
- Tornar o mapa a home funcional da V1 com CTA fixo de corrida e feedback de estados de tile.

## Escopo
- Entregaveis:
  - CTA fixo `Acompanhar corrida` no mapa.
  - Estados visuais consistentes: neutro, dominado, em disputa.
  - Atualizacao de tiles apos submissao sem reiniciar app.

## Fora de escopo
- Reescrever motor de renderizacao Mapbox.
- Introduzir novos modos de mapa fora da V1.

## Pre-requisitos
- `01-fundacao-permissoes-config.md` concluido.
- Acesso de localizacao validado.

## Arquivos iOS impactados
- `ios/LigaRun/Sources/LigaRun/Features/Map/MapScreen.swift`
- `ios/LigaRun/Sources/LigaRun/Features/Map/MapViewModel.swift`
- `ios/LigaRun/Sources/LigaRun/Features/Map/HexMapView.swift`
- `ios/LigaRun/Sources/LigaRun/Features/Runs/RunsView.swift` (navegacao/abertura companion)
- `ios/LigaRun/Tests/LigaRunTests/` (novos testes de view model)

## Tarefas detalhadas
1. Inserir CTA fixo no mapa para abrir fluxo companion.
2. Revisar paleta/estilo dos tiles para os 3 estados obrigatorios.
3. Garantir foco em tile no retorno de resultado (`Ver no mapa`).
4. Implementar refresh de tiles acionado por evento de submissao concluida.
5. Validar performance de refresh em viewport ativo.

## Criterios de pronto
1. Mapa abre como home com CTA visivel e acionavel.
2. Estados de tile sao visualmente distinguiveis e coerentes com GDS.
3. Tile muda no mapa apos corrida sem restart.
4. Sem regressao de toque/selecao de tile.

## Plano de testes
1. Unitario: `MapViewModel` atualiza tiles em refresh.
2. Unitario: foco em tile por `mapFocusTileId`.
3. Manual: completar corrida e observar tile atualizado na home.
4. Manual: validar estado neutro/dominado/disputa em casos reais.
5. Caso mapeado GDS: `Mapa reflete estado do tile apos resultado`.

## Riscos
- Carga frequente de tiles pode degradar performance.
- Inconsistencia de cor quando backend nao retorna `ownerColor`.

## Handoff para proximo passo
- Confirmar contrato de refresh para `05-resultado-pos-corrida.md`.
- Registrar screenshots de estados no PR.
