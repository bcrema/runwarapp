# 06 - Perfil Social e CTAs

## Issue canonica
`GDS v3 iOS / 06 - Perfil social e CTAs`

## Objetivo
- Dono sugerido: `Agente iOS Profile`.
- Dar ao perfil papel ativo de navegacao para o jogo social, sem expandir analytics.

## Subagentes
- `06A` Card `Minha bandeira`.
- `06B` CTAs cruzados.
- `06C` Empty states por contexto.

## Escopo
- Entregaveis:
  - card `Minha bandeira` no perfil;
  - CTAs para `Ranking`, `Minha equipe` e `Mapa`;
  - empty states adequados para usuario sem bandeira.
- Fora de escopo:
  - badges;
  - missoes;
  - ranking solo;
  - graficos extras.

## Arquivos iOS impactados (minimo)
- `ios/LigaRun/Sources/LigaRun/Features/Profile/ProfileView.swift`
- `ios/LigaRun/Sources/LigaRun/App/SessionStore.swift`

## Tarefas detalhadas
1. Inserir o card social sem poluir o bloco existente de stats/historico.
2. Tratar dois caminhos:
   - usuario com bandeira;
   - usuario sem bandeira.
3. Ligar CTAs ao shell de navegacao definido no passo `02`.
4. Preservar o fluxo atual de salvar perfil e logout.

## Criterios de pronto
1. O perfil deixa de ser somente leitura e vira ponto de entrada para a camada social.
2. O usuario sem bandeira recebe CTA util, nao erro seco.
3. Nao ha regressao no historico e stats atuais.

## Plano de testes
1. Testes unitarios do view model/composicao para usuario com e sem bandeira.
2. Smoke manual:
   - perfil -> ranking;
   - perfil -> minha equipe;
   - perfil -> mapa com filtro social.

## Dependencias
- Iniciar apos `02` e `04`.
- Libera `09`.

## Handoff
- Registrar na issue os CTAs finais aceitos para validacao manual em `08` e `09`.

