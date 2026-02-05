# 09 - Hardening release

## Objetivo
- Dono sugerido: `Agente iOS Release`.
- Consolidar estabilidade, performance e consistencia de UX antes da entrega V1.

## Escopo
- Entregaveis:
  - Checklist final de regressao funcional.
  - Validacao de performance/latencia do fluxo sync -> upload -> resultado.
  - Revisao final de strings e consistencia de UX com GDS.
  - Pacote de evidencias para PR final.

## Fora de escopo
- Novos features fora do GDS V1.
- Mudancas de backend ou migrações de schema.

## Pre-requisitos
- Conclusao de `03`, `04`, `05`, `06`, `07`.
- Relatorio de `08-testes-qa-gates.md` disponivel.

## Arquivos iOS impactados
- `ios/LigaRun/Sources/LigaRun/**` (ajustes finais pontuais)
- `ios/LigaRun/Tests/LigaRunTests/**` (fixes de estabilidade)
- `ios/LigaRun/README.md` (comandos finais, se necessario)
- `ios/docs/gds-v1-ios/*.md` (status final e evidencias)

## Tarefas detalhadas
1. Rodar checklist de regressao em fluxos principais (mapa, corridas, bandeiras, perfil).
2. Medir latencia de upload/validacao em rede estavel e registrar valores.
3. Revisar consistencia de textos de erro/sucesso com terminologia do GDS.
4. Garantir que nao haja warnings criticos ou crashes conhecidos.
5. Executar suite final:
   - `cd ios/LigaRun && xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17" test`
6. Consolidar evidencias:
   - screenshots principais;
   - logs de smoke real;
   - resumo de criterios de aceite.

## Criterios de pronto
1. Regressao funcional fechada sem bloqueios P0/P1.
2. Suite de testes verde.
3. Smoke real concluido e documentado.
4. Criterios do GDS V1 iOS marcados como atendidos.
5. PR final pronto para revisao.

## Plano de testes
1. Repetir os 6 casos de aceite do passo `08`.
2. Rodar smoke de ponta a ponta no fluxo principal:
   - Fitness/Saude -> sync -> validacao -> territorio -> mapa.
3. Validar cenarios de erro:
   - sem permissao;
   - sem rede;
   - corrida invalida.

## Riscos
- Ajustes finais podem introduzir regressao tardia.
- Dependencia de ambiente real para validar latencia e HealthKit.

## Handoff para proximo passo
- Encerrar com PR final e checklist de aceite anexado.
- Se houver bloqueio critico, reabrir etapa responsavel (`02` a `07`) com bug especifico.
