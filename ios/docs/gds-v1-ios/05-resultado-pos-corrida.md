# 05 - Resultado pos-corrida

## Objetivo
- Dono sugerido: `Agente iOS UX Flow`.
- Refatorar resumo pos-corrida para o formato clean do GDS com foco no impacto territorial.

## Escopo
- Entregaveis:
  - Tela de resultado com cabecalho, metricas e card territorial principal.
  - Razoes de invalidade claras para treino salvo sem efeito competitivo.
  - Acao `Ver no mapa` levando ao tile afetado.

## Fora de escopo
- Sistema de badges/missoes/rankings.
- Historico completo de corrida nesta tela.

## Pre-requisitos
- `02-sync-healthkit-pipeline.md` concluido.
- Resultado de submissao padronizado disponivel.

## Arquivos iOS impactados
- `ios/LigaRun/Sources/LigaRun/Features/Runs/RunsView.swift` (`SubmissionResultView`)
- `ios/LigaRun/Sources/LigaRun/Features/Runs/MissionSummaryView.swift`
- `ios/LigaRun/Sources/LigaRun/Features/Map/MapScreen.swift` (retorno/foco)
- `ios/LigaRun/Sources/LigaRun/App/SessionStore.swift` (sinalizacao de foco)
- `ios/LigaRun/Tests/LigaRunTests/` (novos testes de formatacao/estado)

## Tarefas detalhadas
1. Reorganizar layout de `SubmissionResultView` para resumo clean.
2. Exibir status territorial principal: conquistou/atacou/defendeu/sem efeito.
3. Exibir metricas essenciais: distancia, tempo, tile e escudo antes/depois.
4. Traduzir e agrupar razoes de invalidade/fraud flags de forma legivel.
5. Garantir que `Ver no mapa` foque no tile alvo quando disponivel.

## Criterios de pronto
1. Usuario entende em segundos se corrida teve impacto territorial.
2. Corrida invalida deixa claro que treino foi salvo, sem efeito competitivo.
3. Navegacao para mapa funciona de forma consistente.
4. Sem regressao no carregamento de resultados offline pendentes.

## Plano de testes
1. Unitario: traducao e mapeamento de reasons para texto de UX.
2. Unitario: prioridade de `tileFocusId` entre campos possiveis.
3. Manual: resultado valido com acao territorial.
4. Manual: resultado invalido com razoes e sem acao.
5. Caso mapeado GDS: `Corrida invalida salva sem efeito competitivo`.

## Riscos
- Excesso de informacao no resumo pode reduzir legibilidade.
- Campos opcionais nulos podem quebrar composicao visual se nao tratados.

## Handoff para proximo passo
- Alinhar com `04-mapa-home-cta-tiles.md` sobre refresh/foco de tile.
- Enviar checklist visual para validacao final em `09-hardening-release.md`.
