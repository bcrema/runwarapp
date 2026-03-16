# 03 - Mapa e Filtros de Territorio

## Issue canonica
`GDS v3 iOS / 03 - Mapa e filtros de territorio`

## Objetivo
- Dono sugerido: `Agente iOS Maps`.
- Transformar o mapa em tela de decisao, com filtros territoriais orientados ao corredor e a assessoria.

## Subagentes
- `03A` Barra de filtros e UX de estados.
- `03B` Estrategia de carregamento por filtro.
- `03C` Detalhe de quadra com contexto ampliado.

## Escopo
- Entregaveis:
  - filtros `Todas`, `Em disputa`, `Minhas`, `Da minha bandeira`;
  - carregamento correto por filtro;
  - detalhe de quadra mostrando dono, campeao, guardiao e estado territorial.
- Fora de escopo:
  - ranking;
  - gestao de roles.

## Arquivos iOS impactados (minimo)
- `ios/LigaRun/Sources/LigaRun/Features/Map/MapViewModel.swift`
- `ios/LigaRun/Sources/LigaRun/Features/Map/MapScreen.swift`
- `ios/LigaRun/Sources/LigaRun/Features/Map/HexMapView.swift`

## Tarefas detalhadas
1. Implementar a barra de filtros usando `MapOwnershipFilter`.
2. Definir estrategia por filtro:
   - `Todas`: viewport atual;
   - `Em disputa`: endpoint dedicado de disputa;
   - `Minhas`: quadras do usuario logado;
   - `Da minha bandeira`: quadras da bandeira atual.
3. Tratar estados especiais:
   - usuario sem bandeira;
   - lista vazia para filtro;
   - erro por endpoint.
4. Evoluir `QuadraDetailView` com contexto util para decisao competitiva.

## Criterios de pronto
1. O corredor consegue alternar filtros sem perder contexto da camera.
2. O filtro `Da minha bandeira` deixa claro quando nao ha bandeira ativa.
3. O detalhe da quadra ajuda a decidir se vale competir ou defender.

## Plano de testes
1. Atualizar `MapViewModelTests` para todos os filtros.
2. Cobrir mensagens de erro e empty states.
3. Smoke manual:
   - alternar filtros;
   - abrir detalhe;
   - navegar de ranking/equipe para mapa.

## Dependencias
- Iniciar apos `02` e `04`.
- Libera `09`.

## Handoff
- Publicar na issue os contratos finais de filtro e os gatilhos de foco aceitos pelo mapa.

