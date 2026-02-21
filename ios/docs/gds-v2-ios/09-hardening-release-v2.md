# 09 - Hardening e Release Readiness (V2 Quadras)

## Objetivo
- Dono sugerido: `Agente iOS Release`.
- Consolidar a migracao v2 para entrega segura, com foco em regressao, performance e consistencia de UX.

## Escopo
- Entregaveis:
  - Passagem final de regressao.
  - Revisao de performance basica de mapa/runtime.
  - Evidencias para PR final.
- Fora de escopo:
  - Novas features alem do escopo v2.

## Tarefas detalhadas
1. Executar gate final de testes completo.
2. Validar mapa em uso continuo:
   - refresh frequente em viewport.
   - tap/foco em quadras.
3. Validar corrida completa:
   - elegivel em competitivo.
   - inelegivel em treino.
4. Validar pos-corrida:
   - metricas
   - foco de quadra
   - textos finalizados
5. Revisar consistencia de nomenclatura:
   - sem termos legados de `tile` no fluxo alvo.
6. Atualizar `STATUS.md` com resumo final de readiness.

## Criterios de pronto
1. Sem regressao visivel em Mapa + Corrida + Resultado.
2. Testes automatizados verdes.
3. Evidencias (logs/comandos/smoke) anexadas ao status e PR.
4. Checklist de decisoes do `00` completamente atendido.

## Plano de testes
1. `xcodegen generate`
2. `xcodebuild ... test` completo
3. Smoke manual em simulador:
   - fluxo feliz competitivo
   - fluxo inelegivel treino
   - erro de rede em mapa e retry

## Dependencias
- Iniciar apos `04`,`05`,`06`,`07`,`08`.
- Etapa final antes de merge.

