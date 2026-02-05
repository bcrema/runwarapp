# 03 - Companion HUD estados

## Objetivo
- Dono sugerido: `Agente iOS Runtime/UX`.
- Estruturar maquina de estados do companion e refletir sync/upload no HUD.

## Escopo
- Entregaveis:
  - Novo protocolo `RunSyncCoordinating`.
  - Novo tipo `CompanionSyncState`.
  - HUD com estados claros: corrida, aguardando sync, enviando, concluido, falha.
  - Encerramento da corrida acoplado ao trigger de sincronizacao.

## Fora de escopo
- Redesenho total da tela companion fora do necessario para estados.
- Recursos watchOS ou notificacoes push.

## Pre-requisitos
- `02-sync-healthkit-pipeline.md` concluido.
- Payload e fluxo de submissao funcionando.

## Arquivos iOS impactados
- `ios/LigaRun/Sources/LigaRun/Features/Runs/ActiveRunHUD.swift`
- `ios/LigaRun/Sources/LigaRun/Features/Runs/CompanionRunManager.swift`
- `ios/LigaRun/Sources/LigaRun/Features/Runs/RunManager.swift`
- `ios/LigaRun/Sources/LigaRun/Features/Runs/RunsViewModel.swift`
- `ios/LigaRun/Sources/LigaRun/Features/Runs/` (novo coordinator de sync)
- `ios/LigaRun/Tests/LigaRunTests/` (novos testes de estado)

## Tarefas detalhadas
1. Definir `CompanionSyncState` com transicoes deterministicas.
2. Implementar `RunSyncCoordinating` para orquestrar stop -> sync -> upload -> resultado.
3. Adaptar `ActiveRunHUD` para exibir status textual e visual por estado.
4. Tratar cancelamento, timeout e erro com opcao de retry.
5. Garantir que o app nao fique preso em estado intermediario apos falha.

## Criterios de pronto
1. Toda transicao de estado tem gatilho claro e testavel.
2. Usuario entende quando corrida esta sincronizando e quando concluiu.
3. Erros exibem acao de recuperacao sem perder dados locais.
4. Resultado final chega ao fluxo de resumo sem navegar manualmente.

## Plano de testes
1. Unitario: transicoes validas de `CompanionSyncState`.
2. Unitario: coordinator dispara sync no encerramento da corrida.
3. Unitario: falha de upload leva para estado de erro + retry.
4. Manual: iniciar, encerrar e observar transicoes no HUD.
5. Caso mapeado GDS: `Corrida invalida salva sem efeito competitivo`.

## Riscos
- Corridas em background podem interromper transicoes visuais.
- Race condition entre finalizacao da corrida e chegada da rota HealthKit.

## Handoff para proximo passo
- Enviar payload de estado e resultado para `05-resultado-pos-corrida.md`.
- Publicar diagrama simples de estados no PR para revisao rapida.
