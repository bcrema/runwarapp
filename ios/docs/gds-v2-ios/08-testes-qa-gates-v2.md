# 08 - Testes, QA e Gates de Merge (V2 Quadras)

## Objetivo
- Dono sugerido: `Agente iOS QA`.
- Garantir cobertura de testes e gate de merge para a migracao v2 sem regressao funcional.

## Escopo
- Entregaveis:
  - Matriz de testes unitarios por passo.
  - Sequencia de execucao de testes por rodada.
  - Checklist de smoke manual para mapa/corrida/resultado.
  - Gate final unico para merge.

## Matriz de QA por passo (cobertura minima obrigatoria)
| Passo | Objetivo funcional | Suites obrigatorias | Cenarios minimos a validar |
|---|---|---|---|
| `02` Mapa quadras | Renderizacao, foco e interacao por quadra | `MapViewModelTests` | carga de quadras no mapa, selecao de `quadraId`, fallback de erro amigavel |
| `03` Elegibilidade local | Regra campeao/dono e pre-validacao | `QuadraEligibilityPolicyTests` | campeao elegivel, dono elegivel, inelegivel vira treino |
| `04` Companion HUD | Alternancia competitivo/treino | `CompanionRunManagerTests` | mudanca de modo por quadra corrente, consistencia visual/estado |
| `05` Sync/upload | Persistencia e envio com modo correto | `RunSyncCoordinatorTests`, `RunUploadServiceTests`, `RunSessionStoreTests` | roteamento por `quadraId`, payload competitivo/treino, decode legado |
| `06` Resultado | Pos-corrida com foco em quadra | `SubmissionResultPresentationTests` | exibicao de `Quadra foco`, CTA de retorno ao mapa |

## Sequencia oficial por rodada (execucao incremental)
1. **Rodada 1 (imediata, em paralelo)**
   - `MapViewModelTests`
   - `QuadraEligibilityPolicyTests`
2. **Rodada 2 (apos 01+03)**
   - `CompanionRunManagerTests`
   - `RunSyncCoordinatorTests`
   - `RunUploadServiceTests`
3. **Rodada 3 (apos 02+05)**
   - `SubmissionResultPresentationTests`
   - `RunSessionStoreTests`
4. **Gate final de merge (unico)**
   - comando completo `xcodebuild ... test` sem `-only-testing`.

## Suites obrigatorias (minimo)
1. `MapViewModelTests`
2. `QuadraEligibilityPolicyTests` (novo)
3. `CompanionRunManagerTests`
4. `RunSyncCoordinatorTests`
5. `RunUploadServiceTests`
6. `SubmissionResultPresentationTests`
7. `RunSessionStoreTests`

## Tarefas detalhadas
1. Garantir que cada passo entregue inclui teste correspondente atualizado.
2. Cobrir cenarios novos de modo competitivo/treino.
3. Cobrir foco por `quadraId`.
4. Cobrir decode legado em `RunSessionStore`.
5. Consolidar comandos oficiais executados no `STATUS.md`.

## Comandos de referencia
1. Geração de projeto:
   - `cd ios/LigaRun && xcodegen generate`
2. Testes pontuais por suite:
   - `xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17,OS=26.2" -only-testing:LigaRunTests/<SUITE> test`
3. Gate final:
   - `xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17,OS=26.2" test`

## Checklist de smoke manual
1. Mapa carrega quadras e permite toque/foco.
2. Companion alterna modo competitivo/treino conforme quadra atual.
3. Corrida inelegivel finaliza e sobe como treino.
4. Resultado exibe `Quadra foco` e navega para mapa.
5. Erros de rede no mapa/corrida continuam com mensagens amigaveis.

## Criterios de pronto
1. Todas as suites obrigatorias verdes.
2. Gate final verde no comando completo.
3. Smoke manual registrado no `STATUS.md`.

## Gate de merge (checklist unico)
Para liberar merge do pacote v2:
1. Suites obrigatorias executadas e verdes na branch.
2. `STATUS.md` atualizado com inicio/fim do passo e comandos reais executados.
3. Smoke manual registrado (5 itens) com resultado.
4. Sem regressao aberta para mapa, companion, upload ou resultado.
5. Gate final `xcodebuild ... test` verde na mesma revisao que sera mergeada.

## Dependencias
- Pode iniciar imediato e rodar continuamente.
