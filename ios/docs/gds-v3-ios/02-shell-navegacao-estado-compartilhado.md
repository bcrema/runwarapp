# 02 - Shell, Navegacao e Estado Compartilhado

## Issue canonica
`GDS v3 iOS / 02 - Shell, navegacao e estado compartilhado`

## Objetivo
- Dono sugerido: `Agente iOS App Shell`.
- Centralizar intents de navegacao entre tabs e o estado compartilhado da wave v3.

## Subagentes
- `02A` Navegacao cruzada entre tabs.
- `02B` `SessionStore` e estado de hub/mapa.
- `02C` Consumo e limpeza de intents de foco/filtro.

## Escopo
- Entregaveis:
  - estado compartilhado para:
    - filtro ativo do mapa;
    - contexto de bandeira focada;
    - aba ativa do hub de bandeiras;
  - roteamento entre `Perfil`, `Bandeiras` e `Mapa`.
- Fora de escopo:
  - implementacao visual dos filtros do mapa;
  - lista de membros e roles.

## Arquivos iOS impactados (minimo)
- `ios/LigaRun/Sources/LigaRun/App/SessionStore.swift`
- `ios/LigaRun/Sources/LigaRun/App/MainTabView.swift`
- `ios/LigaRun/Sources/LigaRun/Features/Map/MapScreen.swift`
- `ios/LigaRun/Sources/LigaRun/Features/Bandeiras/BandeirasView.swift`
- `ios/LigaRun/Sources/LigaRun/Features/Profile/ProfileView.swift`

## Tarefas detalhadas
1. Definir no `SessionStore` os intents canonicos da wave:
   - aba do hub de bandeiras;
   - filtro de mapa;
   - contexto de dono/bandeira para foco.
2. Garantir que CTAs cruzados consumam intents uma vez e limpem o estado apos uso.
3. Padronizar a sequencia:
   - CTA no perfil ou ranking
   - troca de tab
   - aplicacao de filtro/contexto
   - limpeza do intent.

## Criterios de pronto
1. `Perfil`, `Bandeiras` e `Mapa` compartilham o mesmo contrato de navegacao.
2. Nao existem caminhos paralelos ou duplicados para o mesmo foco.
3. O estado e idempotente: voltar para a tab nao reaplica intents antigos.

## Plano de testes
1. Testes unitarios para `SessionStore` ou view models afetados.
2. Smoke manual:
   - perfil -> ranking;
   - ranking -> mapa;
   - equipe -> mapa.

## Dependencias
- Iniciar apos `01`.
- Libera `03`, `05` e `06`.

## Handoff
- Registrar na issue os nomes finais dos campos do `SessionStore` para uso dos passos seguintes.

