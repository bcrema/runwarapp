# 09 - Hardening e Release V3

## Issue canonica
`GDS v3 iOS / 09 - Hardening e release`

## Objetivo
- Dono sugerido: `Agente iOS Release`.
- Consolidar regressao final, polish e evidencias da wave v3.

## Subagentes
- `09A` Regressao funcional final.
- `09B` Polish de UX, copy e acessibilidade.
- `09C` Evidencias, fechamento de issues e readiness de PR.

## Escopo
- Entregaveis:
  - regressao final de mapa, hub de bandeiras, equipe e perfil;
  - verificacao de textos e estados de erro;
  - checklist final da release na issue.
- Fora de escopo:
  - novas features;
  - contratos backend ausentes do passo `07`.

## Tarefas detalhadas
1. Rodar a suite automatizada completa do iOS.
2. Executar smoke manual dirigido:
   - ranking -> ver territorio;
   - minha equipe -> role admin;
   - perfil -> CTAs;
   - mapa com filtros.
3. Revisar consistencia de copy:
   - `quadra` vs `tile`;
   - `bandeira` vs `equipe`;
   - mensagens de erro e empty state.
4. Revisar acessibilidade minima:
   - labels dos CTAs;
   - estados desabilitados;
   - leitura de ranking e roster.
5. Consolidar links/refs das issues fechadas no comentario final da issue `09`.

## Criterios de pronto
1. Nenhuma regressao critica aberta na wave principal.
2. Evidencia automatizada e manual centralizada na issue `09`.
3. Passos `03`,`04`,`05`,`06`,`08` fechados.
4. Passo `07` corretamente isolado como dependente de backend.

## Plano de testes
1. `cd ios/LigaRun && xcodegen generate`
2. `cd ios/LigaRun && xcodebuild -project LigaRun.xcodeproj -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17,OS=26.2" test`
3. Smoke manual completo da wave.

## Dependencias
- Iniciar apos `03`,`04`,`05`,`06`,`08` concluidos.

## Handoff
- Fechar a issue com comentario final contendo:
  - resumo da release;
  - evidencias de teste;
  - pendencias remanescentes;
  - referencia explicita ao passo `07`.

