# Tarefas de Agentes - Plano Mestre (GDS v3 iOS)

## Objetivo
Referencia oficial de delegacao por rodadas para a wave iOS orientada por GitHub Issues.

## Regras obrigatorias
1. Ler antes de codar:
   - `ios/docs/gds-v3-ios/00-decisoes-v3-ios.md`
   - `ios/docs/gds-v3-ios/README.md`
   - `ios/docs/gds-v3-ios/ONBOARDING-AGENTES.md`
2. Trabalhar somente no passo atribuido.
3. Nao alterar backend como parte desta wave.
4. Padrao obrigatorio: `1 agente = 1 passo = 1 branch = 1 worktree = 1 issue`.
5. Subagentes nao ganham issue propria; ficam no checklist da issue do passo.
6. Se houver bloqueio, comentar na issue e pausar imediatamente.
7. Nao fechar a issue sem testes executados e registrados.
8. Passos `03`,`04`,`05`,`06` e `09` devem seguir a matriz e os gates definidos em `ios/docs/gds-v3-ios/08-testes-qa-gates-v3.md`.

## Labels sugeridas
1. `gds-v3-ios`
2. `ios`
3. `blocked`
4. `qa`
5. `release`
6. `backend-dependency`
7. `codex`

## Contrato de atualizacao das issues
Toda atualizacao relevante deve ser feita por comentario na issue do passo contendo:
1. `Status`
2. `Resumo tecnico`
3. `Branch/worktree`
4. `Testes`
5. `Bloqueios`, quando houver

Template de inicio:
```text
Status: In Progress
Resumo tecnico: passo iniciado; contexto carregado e subagentes alinhados.
Branch/worktree: feat/ios-gds-v3-<passo>-<slug> em ../runwarapp-wt-v3-<passo>
Testes: ainda nao executados.
Bloqueios: nenhum.
```

Template de bloqueio:
```text
Status: Blocked
Resumo tecnico: <motivo objetivo do bloqueio>.
Branch/worktree: <branch> em <path>
Testes:
- <comando> (<resultado>)
Bloqueios:
- <acao necessaria para destravar>
```

Template de conclusao:
```text
Status: Done
Resumo tecnico: <o que foi entregue>.
Branch/worktree: <branch> em <path>
Testes:
- <comando> (<resultado>)
- <comando> (<resultado>)
Smoke manual:
- <cenario/persona> (<resultado>)
Bloqueios: nenhum.
```

## Fluxo oficial com gh
1. Ver as issues da wave:
   - `gh issue list --search "GDS v3 iOS" --state open`
2. Abrir detalhes da issue:
   - `gh issue view <ISSUE_NUM>`
3. Registrar progresso:
   - `gh issue comment <ISSUE_NUM> --body-file <arquivo-ou-temp-file>`
4. Fechar a issue ao concluir:
   - `gh issue close <ISSUE_NUM> --comment "Status: Done ..."`

## Rodadas e gates
| Rodada | Passos | Gate para iniciar | Gate para liberar a proxima |
|---|---|---|---|
| `1` | `01`,`07`,`08` | imediato | `01` em `Done` com testes |
| `2` | `02`,`04` | `01` em `Done` com testes | `02` e `04` em `Done` com testes |
| `3` | `03`,`05`,`06` | `02` e `04` em `Done` com testes | `03`,`05`,`06` em `Done` com testes |
| `Final` | `09` | `03`,`04`,`05`,`06`,`08` em `Done` com testes | encerramento |

## Mapa de issues por passo
| Passo | Issue | Titulo da issue | Labels minimas |
|---|---|---|
| `01` | `#79` | `GDS v3 iOS / 01 - Contrato e servicos territorio/equipe` | `gds-v3-ios`, `ios`, `codex` |
| `02` | `#80` | `GDS v3 iOS / 02 - Shell, navegacao e estado compartilhado` | `gds-v3-ios`, `ios`, `codex` |
| `03` | `#81` | `GDS v3 iOS / 03 - Mapa e filtros de territorio` | `gds-v3-ios`, `ios`, `codex` |
| `04` | `#82` | `GDS v3 iOS / 04 - Bandeiras hub, explorar e ranking` | `gds-v3-ios`, `ios`, `codex` |
| `05` | `#83` | `GDS v3 iOS / 05 - Minha equipe, top contribuidores e roles` | `gds-v3-ios`, `ios`, `codex` |
| `06` | `#84` | `GDS v3 iOS / 06 - Perfil social e CTAs` | `gds-v3-ios`, `ios`, `codex` |
| `07` | `#85` | `GDS v3 iOS / 07 - Trilhas dependentes de backend` | `gds-v3-ios`, `ios`, `blocked`, `backend-dependency`, `codex` |
| `08` | `#86` | `GDS v3 iOS / 08 - Testes, QA e gates` | `gds-v3-ios`, `ios`, `qa`, `codex` |
| `09` | `#87` | `GDS v3 iOS / 09 - Hardening e release` | `gds-v3-ios`, `ios`, `release`, `codex` |

## Prompt base para delegacao
```text
Voce e o dono do passo <PASSO>. Execute somente o que esta em ios/docs/gds-v3-ios/<ARQUIVO-DO-PASSO>.

Regras:
1) Nao alterar backend.
2) Cumprir criterios de pronto e plano de testes do passo.
3) Trabalhar em worktree dedicado e branch dedicada do passo.
4) Registrar inicio, bloqueio e conclusao por comentario na issue do passo.
5) Nao usar STATUS.md; a issue e a unica fonte de status.
6) Nao fechar a issue sem testes passando.
```

## Checklist do orquestrador
1. Validar dependencias antes de liberar nova rodada.
2. Garantir que toda issue iniciada recebeu comentario de `In Progress`.
3. Garantir que toda issue bloqueada explicita a acao de destravamento.
4. Garantir que toda issue fechada contem comandos de teste e resultado.
5. Garantir que a issue `07` nao bloqueie a wave principal por engano.
