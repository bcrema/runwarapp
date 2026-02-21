# 00 - Decisoes V2 iOS (Quadras)

## Decisoes registradas
1. Escopo desta versao: somente iOS.
2. Contrato iOS: somente novo dominio `quadra` (sem fallback para `tile`).
3. Fluxo alvo obrigatorio: `Mapa + Corrida + Resultado`.
4. Pre-validacao local obrigatoria para elegibilidade competitiva.
5. Regra de elegibilidade:
   - elegivel se usuario for `dono` da quadra; ou
   - elegivel se usuario for `campeao` da quadra.
6. `campeao` valido por:
   - `championUserId == currentUser.id`; ou
   - `championBandeiraId == currentUser.bandeiraId`.
7. Enforco de regra: bloqueio competitivo, nao bloqueio de corrida.
8. Corrida inelegivel:
   - continua normalmente;
   - deve ser enviada em modo `TRAINING`.
9. Nomenclatura padrao: `quadra`/`quadras` em modelos, payloads e UX.
10. Foco de mapa pos-submissao: usar `quadraId`.
11. Branching/worktree obrigatorio: `1 agente = 1 branch de feature = 1 worktree`.
12. Gate final de testes: `xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17,OS=26.2" test` passando.

## Convencoes operacionais
1. Um arquivo = um passo = um agente dono principal.
2. Cada passo precisa de criterio de pronto e testes explicitos.
3. Bloqueios tecnicos devem ser registrados em `STATUS.md` com acao de destravamento.

## Referencias
1. `GDS v1.0 - iOS.md`
2. `ios/AGENTS.md`
3. `ios/docs/gds-v2-ios/README.md`
