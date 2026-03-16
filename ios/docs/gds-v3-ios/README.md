# GDS v3 iOS - Corredor + Assessoria (Execucao via GitHub Issues)

## Visao geral
Este pacote organiza a proxima wave funcional do iOS em passos independentes e paralelizaveis, com foco em:
- mapa com filtros territoriais;
- hub de bandeiras com explorar + ranking;
- minha equipe com top contribuidores e roles;
- perfil com CTAs sociais;
- trilha separada para dependencias de backend.

Ao contrario dos pacotes `gds-v1-ios` e `gds-v2-ios`, o acompanhamento oficial deste pacote nao usa `STATUS.md`.
O andamento fica no GitHub do repositorio, com `1 issue = 1 passo = 1 agente dono = 1 branch = 1 worktree`.

## Fonte oficial de status
1. `GitHub Issues` e a unica fonte de status deste pacote.
2. `00-decisoes-v3-ios.md` nao vira issue; e a referencia obrigatoria.
3. Cada passo `01` a `09` deve ter uma issue propria com titulo canonico.
4. Inicio, bloqueio, conclusao e testes devem ser registrados por comentario na issue.
5. Fechar a issue significa `Done`.

## Issues oficiais da wave
| Passo | Issue | Titulo canonico |
|---|---|
| `01` | `#79` | `GDS v3 iOS / 01 - Contrato e servicos territorio/equipe` |
| `02` | `#80` | `GDS v3 iOS / 02 - Shell, navegacao e estado compartilhado` |
| `03` | `#81` | `GDS v3 iOS / 03 - Mapa e filtros de territorio` |
| `04` | `#82` | `GDS v3 iOS / 04 - Bandeiras hub, explorar e ranking` |
| `05` | `#83` | `GDS v3 iOS / 05 - Minha equipe, top contribuidores e roles` |
| `06` | `#84` | `GDS v3 iOS / 06 - Perfil social e CTAs` |
| `07` | `#85` | `GDS v3 iOS / 07 - Trilhas dependentes de backend` |
| `08` | `#86` | `GDS v3 iOS / 08 - Testes, QA e gates` |
| `09` | `#87` | `GDS v3 iOS / 09 - Hardening e release` |

## Estrategia de paralelizacao
1. Padrao obrigatorio: `1 agente = 1 branch = 1 worktree = 1 issue`.
2. Subagentes ficam como checklist interno da issue do passo.
3. Nenhum passo deve manter progresso paralelo em arquivo local de status.
4. Toda dependencia deve aparecer:
   - no arquivo do passo;
   - em `TAREFAS-AGENTES.md`;
   - no corpo da issue.

## Ordem sugerida de execucao
1. Ler `00-decisoes-v3-ios.md`.
2. Rodada 1: `01`, `07`, `08`.
3. Rodada 2: `02`, `04` apos `01`.
4. Rodada 3: `03`, `05`, `06` apos `02` e `04`.
5. Rodada final: `09`.

## Matriz de paralelizacao
| Passo | Pode iniciar quando | Pode rodar em paralelo com |
|---|---|---|
| `01` Contrato e servicos | imediato | `07`, `08` |
| `02` Shell e navegacao | apos `01` | `04` |
| `03` Mapa e filtros | apos `02` e `04` | `05`, `06` |
| `04` Bandeiras hub e ranking | apos `01` | `02` |
| `05` Minha equipe e roles | apos `02` e `04` | `03`, `06` |
| `06` Perfil social e CTAs | apos `02` e `04` | `03`, `05` |
| `07` Dependencias de backend | imediato | todos |
| `08` QA e gates | imediato e evolutivo | todos |
| `09` Hardening e release | apos `03`,`04`,`05`,`06`,`08` | nenhum |

## Definicao de done global
1. Passos funcionais implementados no iOS, sem alterar backend.
2. Suites automatizadas do iOS verdes no comando oficial.
3. Smoke manual dirigido registrado na issue do passo ou na issue `09`.
4. Nenhum passo fechado sem comentario final contendo:
   - status;
   - resumo tecnico;
   - branch/worktree;
   - comandos de teste e resultado.
5. Passos dependentes de backend podem permanecer abertos e bloqueados sem travar a wave principal, desde que isso esteja explicito.

## Arquivos de coordenacao
1. `ios/docs/gds-v3-ios/TAREFAS-AGENTES.md`
2. `ios/docs/gds-v3-ios/ONBOARDING-AGENTES.md`
3. `ios/docs/gds-v3-ios/00-decisoes-v3-ios.md`
4. `ios/docs/gds-v3-ios/01-09` arquivos de passo
