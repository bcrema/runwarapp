# 04 - Bandeiras Hub, Explorar e Ranking

## Issue canonica
`GDS v3 iOS / 04 - Bandeiras hub, explorar e ranking`

## Objetivo
- Dono sugerido: `Agente iOS Social Hub`.
- Evoluir a tab `Bandeiras` de lista simples para hub funcional da comunidade.

## Subagentes
- `04A` Superficie `Explorar`.
- `04B` Superficie `Ranking`.
- `04C` CTA `Ver territorio` a partir do ranking.

## Escopo
- Entregaveis:
  - shell do hub com `Explorar`, `Ranking` e placeholder/gancho para `Minha equipe`;
  - ranking de bandeiras usando o contrato atual;
  - CTA `Ver territorio` emitindo intent para o mapa.
- Fora de escopo:
  - lista de membros;
  - mutacao de role.

## Arquivos iOS impactados (minimo)
- `ios/LigaRun/Sources/LigaRun/Features/Bandeiras/BandeirasView.swift`
- `ios/LigaRun/Sources/LigaRun/Features/Bandeiras/BandeirasViewModel.swift`
- `ios/LigaRun/Sources/LigaRun/App/SessionStore.swift`

## Tarefas detalhadas
1. Reorganizar a tela em hub sem perder o fluxo atual de criar/entrar/sair.
2. Implementar a superficie `Ranking` com:
   - posicao;
   - nome;
   - membros;
   - total de territorio;
   - CTA `Ver territorio`.
3. Garantir estados independentes por superficie:
   - loading;
   - erro;
   - vazio.
4. Deixar ponto de extensao claro para o passo `05`.

## Criterios de pronto
1. A tab `Bandeiras` funciona como hub e nao como lista unica.
2. O ranking e legivel e navegavel.
3. O CTA `Ver territorio` emite o contexto correto para o passo `02/03`.

## Plano de testes
1. Testes de view model para ranking.
2. Testes dos estados por superficie.
3. Smoke manual:
   - explorar -> criar/entrar/sair;
   - ranking -> ver territorio.

## Dependencias
- Iniciar apos `01`.
- Libera `03`, `05` e `06`.

## Handoff
- Registrar na issue o contrato do CTA `Ver territorio` esperado por `02` e `03`.

