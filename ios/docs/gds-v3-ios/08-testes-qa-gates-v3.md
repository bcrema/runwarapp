# 08 - Testes, QA e Gates V3

## Issue canonica
`GDS v3 iOS / 08 - Testes, QA e gates`

## Objetivo
- Dono sugerido: `Agente iOS QA`.
- Definir a matriz de verificacao da wave e impedir fechamento prematuro das issues funcionais.

## Subagentes
- `08A` Suites automatizadas obrigatorias.
- `08B` Matriz manual por persona.
- `08C` Gate de merge e checklist de fechamento de issue.

## Escopo
- Entregaveis:
  - suites automatizadas obrigatorias por passo;
  - smoke manual por perfil de usuario;
  - gate unico de merge/release.
- Fora de escopo:
  - alterar escopo funcional dos passos;
  - criar fluxo paralelo de status local.

## Suites automatizadas obrigatorias
1. `MapViewModelTests`
2. `BandeirasViewModelTests`
3. testes novos de ranking/equipe/roles
4. `ProfileViewModelTests`
5. `RunUploadServiceTests`
6. `QuadraEligibilityPolicyTests`
7. suite completa `LigaRunTests`

## Matriz manual minima
1. Usuario sem bandeira:
   - explorar bandeiras;
   - perfil com CTA para entrar em bandeira;
   - mapa sem filtro `Da minha bandeira`.
2. Usuario membro:
   - ranking -> ver territorio;
   - minha equipe sem controles admin;
   - perfil -> minha equipe.
3. Usuario admin:
   - mutacao de role;
   - erro de ultimo admin;
   - navegacao equipe -> mapa.

## Gate de fechamento por issue
1. Comentario final com comandos e resultados.
2. Nenhum erro funcional aberto sem acao de follow-up.
3. Checklists de subagentes do passo marcados.
4. Smoke manual registrado quando aplicavel.

## Gate final da wave
1. `xcodegen generate` passando.
2. `xcodebuild ... test` passando na suite completa.
3. Smoke manual de `03`, `04`, `05` e `06` registrado.
4. Issue `09` consolida a evidencia final.

## Dependencias
- Pode iniciar imediato e rodar de forma evolutiva.
- Necessario para liberar `09`.

## Handoff
- Publicar na issue os comandos oficiais e a matriz manual final para reaproveitamento em `09`.

