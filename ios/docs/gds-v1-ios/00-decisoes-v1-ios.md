# 00 - Decisoes V1 iOS

## Decisoes registradas
1. Janela de entrega: `2-3 semanas`.
2. Escopo: `iOS com backend atual` (sem mudancas de contrato backend nesta entrega).
3. Qualidade: `simulador + smoke real`.
4. Apple Watch: `sem app watchOS nativo`.
5. Fluxo principal: `Fitness/Saude -> sincronizacao -> validacao -> territorio`.
6. Regras territoriais, antifraude e caps: backend e fonte de verdade.
7. Branching: sempre branch de feature dedicada; sem commit/merge direto na `main`.
8. Gate final de testes: `xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17" test` passando.

## Convencoes operacionais
1. Um arquivo = um passo = um agente dono principal.
2. Cada passo deve ter criterio de pronto e plano de testes explicito.
3. Bloqueios tecnicos devem ser registrados no proprio arquivo da etapa.

## Referencias
1. `GDS v1.0 - iOS.md`
2. `ios/AGENTS.md`
3. `ios/docs/gds-v1-ios/README.md`
