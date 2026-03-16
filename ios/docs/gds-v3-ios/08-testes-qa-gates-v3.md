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
  - gate unico de merge/release;
  - template reutilizavel para fechamento de issue e consolidacao em `09`.
- Fora de escopo:
  - alterar escopo funcional dos passos;
  - criar fluxo paralelo de status local.

## Arquivos iOS impactados
- `ios/LigaRun/scripts/run-tests.sh`
- `ios/LigaRun/README.md`
- `ios/docs/gds-v3-ios/00-decisoes-v3-ios.md`
- `ios/docs/gds-v3-ios/08-testes-qa-gates-v3.md`
- `ios/docs/gds-v3-ios/09-hardening-release-v3.md`
- `ios/docs/gds-v3-ios/TAREFAS-AGENTES.md`

## Matriz de QA por passo (cobertura minima obrigatoria)
| Passo | Objetivo funcional | Suites obrigatorias | Cenarios minimos a validar |
|---|---|---|---|
| `03` Mapa e filtros | filtros territoriais e navegacao com contexto | `MapViewModelTests` | alternancia `Todas`/`Em disputa`/`Minhas`/`Da minha bandeira`, usuario sem bandeira, erro/empty state, foco vindo de ranking/equipe |
| `04` Bandeiras hub e ranking | explorar, ranking e CTA `Ver territorio` | `BandeirasViewModelTests` | loading/erro/vazio por superficie, ranking carregado, CTA emitindo contexto correto, explorar com criar/entrar/sair preservado |
| `05` Minha equipe e roles | roster, top contribuidores e mutacao admin | `BandeirasViewModelTests` e/ou suite nova dedicada para equipe/roles | roster carregado, top 3 ordenado, membro sem controles admin, mutacao de role com sucesso, erro de permissao insuficiente e erro de ultimo admin |
| `06` Perfil social e CTAs | card `Minha bandeira` e navegacao cruzada | `ProfileViewModelTests` | usuario com bandeira, usuario sem bandeira, CTA para ranking, CTA para minha equipe, CTA para mapa |
| Base v2/v3 ainda obrigatoria | regressao de upload e elegibilidade | `RunUploadServiceTests`, `QuadraEligibilityPolicyTests` | upload segue sem regressao e regras competitivas continuam coerentes |
| Gate final da wave | consolidacao da branch pronta para merge | suite completa `LigaRunTests` | todos os testes unitarios verdes na mesma revisao que sera mergeada |

## Sequencia oficial por rodada (execucao incremental)
1. Rodada 1, imediata:
   - `RunUploadServiceTests`
   - `QuadraEligibilityPolicyTests`
2. Rodada 2, apos `04`:
   - `BandeirasViewModelTests` com foco em `Explorar` e `Ranking`
3. Rodada 3, apos `03`,`05`,`06`:
   - `MapViewModelTests`
   - `BandeirasViewModelTests` com cenarios de equipe/roles
   - `ProfileViewModelTests`
4. Gate final unico:
   - `./scripts/run-tests.sh` sem `XCODE_ONLY_TESTING`

## Suites automatizadas obrigatorias (minimo)
1. `MapViewModelTests`
2. `BandeirasViewModelTests`
3. testes novos de ranking/equipe/roles, aceitos no mesmo arquivo ou em suite dedicada desde que citados no comentario final da issue `05`
4. `ProfileViewModelTests`
5. `RunUploadServiceTests`
6. `QuadraEligibilityPolicyTests`
7. suite completa `LigaRunTests`

## Comandos oficiais de referencia
1. Gerar projeto:
   - `cd ios/LigaRun && xcodegen generate`
2. Rodar suite especifica:
   - `cd ios/LigaRun && XCODE_ONLY_TESTING=MapViewModelTests ./scripts/run-tests.sh`
3. Rodar multiplas suites:
   - `cd ios/LigaRun && XCODE_ONLY_TESTING=MapViewModelTests,BandeirasViewModelTests,ProfileViewModelTests ./scripts/run-tests.sh`
4. Reaproveitar `SourcePackages` ja resolvido:
   - `cd ios/LigaRun && XCODE_CLONED_SOURCE_PACKAGES_DIR_PATH=/path/to/SourcePackages XCODE_DISABLE_AUTOMATIC_PACKAGE_RESOLUTION=1 ./scripts/run-tests.sh`
5. Gate final da branch:
   - `cd ios/LigaRun && ./scripts/run-tests.sh`

## Matriz manual minima
| Persona | Fluxos obrigatorios | Evidencia minima esperada |
|---|---|---|
| Usuario sem bandeira | explorar bandeiras; perfil com CTA para entrar em bandeira; mapa sem filtro `Da minha bandeira` | CTA util sem erro seco, empty state legivel e filtro social sem falso positivo |
| Usuario membro | ranking -> ver territorio; minha equipe sem controles admin; perfil -> minha equipe | navegacao cruzada preserva contexto e nao exibe acoes de admin |
| Usuario admin | mutacao de role; erro de ultimo admin; navegacao equipe -> mapa | sucesso e falhas de role com feedback claro, navegacao equipe/mapa funcional |

## Gate de fechamento por issue
1. Comentario final com comandos e resultados.
2. Suite obrigatoria do passo citada nominalmente e com resultado explicito.
3. Smoke manual registrado quando aplicavel, com persona/cenario/resultado.
4. Nenhum erro funcional aberto sem acao de follow-up.
5. Checklists de subagentes do passo marcados.

Template minimo para conclusao de issue funcional:
```text
Status: Done
Resumo tecnico: <entrega objetiva>.
Branch/worktree: <branch> em <path>
Testes:
- cd ios/LigaRun && XCODE_ONLY_TESTING=<SUITE> ./scripts/run-tests.sh (<resultado>)
- cd ios/LigaRun && ./scripts/run-tests.sh (<resultado ou "executado na issue 09">)
Smoke manual:
- <persona> -> <fluxo> (<resultado>)
Bloqueios: nenhum.
```

## Gate especifico para `03`, `04`, `05` e `06`
1. Passo `03`: nao fecha sem `MapViewModelTests` cobrindo filtros e smoke de navegacao para mapa.
2. Passo `04`: nao fecha sem `BandeirasViewModelTests` cobrindo ranking e smoke `ranking -> ver territorio`.
3. Passo `05`: nao fecha sem testes de equipe/roles e smoke com usuario membro + usuario admin.
4. Passo `06`: nao fecha sem `ProfileViewModelTests` e smoke com usuario sem bandeira + CTA cruzado.

## Gate final da wave
1. `xcodegen generate` passando.
2. `./scripts/run-tests.sh` passando na suite completa.
3. Smoke manual de `03`, `04`, `05` e `06` registrado.
4. Issue `09` consolida a evidencia final.

## Criterios de pronto
1. Toda issue funcional da wave referencia a suite automatizada minima do proprio passo.
2. O passo `05` registra explicitamente onde ficaram os testes novos de ranking/equipe/roles.
3. Os comandos oficiais de teste estao padronizados em `ios/LigaRun/scripts/run-tests.sh`.
4. O comentario final da issue `09` reaproveita a matriz manual final deste passo sem reinterpretacao.

## Dependencias
- Pode iniciar imediato e rodar de forma evolutiva.
- Necessario para liberar `09`.

## Handoff
- Publicar na issue os comandos oficiais, a matriz manual final e o checklist de fechamento para reaproveitamento em `09`.
