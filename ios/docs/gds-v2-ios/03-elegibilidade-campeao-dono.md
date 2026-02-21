# 03 - Elegibilidade Local (Campeao ou Dono)

## Objetivo
- Dono sugerido: `Agente iOS Gameplay Rules`.
- Implementar politica local de elegibilidade competitiva por quadra com regra fechada de campeao/dono.

## Escopo
- Entregaveis:
  - Politica dedicada (`QuadraEligibilityPolicy`) testada.
  - API de avaliacao simples para uso no mapa e no companion.
  - Motivos de inelegibilidade padronizados para UI/log.
- Fora de escopo:
  - Persistencia no pipeline de upload (passo 05).
  - Layout final do companion (passo 04).

## Arquivos iOS impactados (minimo)
- `ios/LigaRun/Sources/LigaRun/Features/Runs/QuadraEligibilityPolicy.swift` (novo)
- `ios/LigaRun/Tests/LigaRunTests/QuadraEligibilityPolicyTests.swift` (novo)

## Regra obrigatoria
1. `isOwner`:
   - `ownerType == SOLO && ownerId == currentUser.id`; ou
   - `ownerType == BANDEIRA && ownerId == currentUser.bandeiraId`.
2. `isChampion`:
   - `championUserId == currentUser.id`; ou
   - `championBandeiraId == currentUser.bandeiraId`.
3. Elegivel se `isOwner || isChampion`.
4. Falta de metadado suficiente => inelegivel por seguranca.

## Tarefas detalhadas
1. Criar enum de status:
   - `eligibleCompetitive`
   - `trainingOnly(reason)`
2. Criar funcao principal:
   - entrada: `User`, `Quadra`
   - saida: status de elegibilidade + razao resumida
3. Definir razoes padrao para UX:
   - `missing_user_context`
   - `missing_quadra_ownership_data`
   - `user_not_owner_nor_champion`
4. Publicar helper para consultas repetidas em runtime.

## Criterios de pronto
1. Politica isolada, deterministica e sem dependencia de UI.
2. Todos os cenarios obrigatorios cobertos por testes.
3. Reuso simples por `ActiveRunHUD` e detalhe de quadra.

## Plano de testes
1. Criar testes:
   - elegivel por dono solo
   - elegivel por dono bandeira
   - elegivel por campeao usuario
   - elegivel por campeao bandeira
   - inelegivel sem metadado
   - inelegivel sem usuario logado/contexto de bandeira

## Dependencias
- Pode iniciar imediato.
- Libera `04` e `05`.

