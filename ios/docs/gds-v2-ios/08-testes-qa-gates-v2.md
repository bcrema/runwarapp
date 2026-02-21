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

## Dependencias
- Pode iniciar imediato e rodar continuamente.

