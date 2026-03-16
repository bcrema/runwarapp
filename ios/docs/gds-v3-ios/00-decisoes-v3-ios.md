# 00 - Decisoes V3 iOS

## Decisoes registradas
1. Escopo desta wave: somente iOS.
2. Fonte oficial de status: `GitHub Issues`; nao usar `STATUS.md`.
3. Fluxo principal desta wave: aumentar utilidade fora do momento da corrida para corredor e assessoria.
4. O app continua com as tabs principais atuais; nao criar nova tab raiz.
5. `Bandeiras` vira hub com tres superficies:
   - `Explorar`
   - `Ranking`
   - `Minha equipe`
6. `Mapa` ganha filtros territoriais:
   - `Todas`
   - `Em disputa`
   - `Minhas`
   - `Da minha bandeira`
7. `Ranking` usa o contrato atual `GET /api/bandeiras/rankings`.
8. `Minha equipe` usa o contrato atual `GET /api/bandeiras/{id}/members`.
9. Mutacao de role usa o contrato atual `PUT /api/bandeiras/{id}/members/role`.
10. `Perfil` ganha card `Minha bandeira` e CTAs para mapa, ranking e equipe.
11. Badges, missoes, ranking solo, presenca semanal e notificacoes ficam em trilha separada dependente de backend.
12. Passo `07` nao bloqueia a release principal.
13. Gate automatizado da wave:
   - `cd ios/LigaRun && xcodegen generate`
   - `cd ios/LigaRun && ./scripts/run-tests.sh`
14. Gate manual da wave:
   - mapa com filtros;
   - ranking -> ver territorio;
   - minha equipe com role admin;
   - perfil -> CTA cruzado.

## Convencoes operacionais
1. `1 agente = 1 passo = 1 branch = 1 worktree = 1 issue`.
2. Subagentes ficam como checklist interno da issue do passo.
3. Nenhum passo deve atualizar arquivo local de status.
4. Bloqueio tecnico deve ser registrado por comentario na issue com acao de destravamento.

## Referencias
1. `GDS v1.0.md`
2. `ios/docs/gds-v1-ios/`
3. `ios/docs/gds-v2-ios/`
4. `ios/AGENTS.md`
