# Tarefas de Agentes - Plano Mestre (GDS v2.0 iOS Quadras)

## Objetivo
Referencia oficial de delegacao por rodadas para a migracao iOS `tile -> quadra` com pre-validacao local e envio por modo de corrida.

## Regras obrigatorias
1. Ler antes de codar:
   - `ios/docs/gds-v2-ios/00-decisoes-v2-ios.md`
   - `ios/docs/gds-v2-ios/README.md`
   - `ios/docs/gds-v2-ios/STATUS.md`
2. Trabalhar somente no passo atribuido.
3. Nao alterar backend.
4. Padrao obrigatorio: `1 agente = 1 passo = 1 branch = 1 worktree`.
5. Se houver bloqueio, registrar no `STATUS.md` e pausar o passo.
6. Nao marcar `Done` sem testes executados e resultado registrado.
7. Nao liberar rodada seguinte sem dependencias em `Done` com testes.

## Contrato de atualizacao do STATUS.md (inicio e fim)
Toda atualizacao deve conter:
1. `status`
2. `resumo tecnico`
3. `branch/worktree`
4. `comandos de teste e resultado`

Template:
```text
- `<PASSO>` <AAAA-MM-DD> - Status: <In Progress|Blocked|Done>.
  Resumo tecnico: <o que foi feito/bloqueio>.
  Branch/worktree: <branch> em <path>.
  Testes: <comandos executados> (<resultado>).
```

## Rodadas e gates
| Rodada | Passos | Gate para iniciar | Gate para liberar proxima |
|---|---|---|---|
| `1` | `01`,`02`,`03`,`08` | imediato | `01` e `03` em `Done` com testes |
| `2` | `04`,`05` | `01` + `03` em `Done` | `02` + `05` em `Done` com testes |
| `3` | `06`,`07` | `02` + `05` em `Done` | `06` + `07` em `Done` com testes |
| `Final` | `09` | `04`,`05`,`06`,`07`,`08` em `Done` | encerramento |

## Prompt base para delegacao
```text
Voce e o dono do passo <PASSO>. Execute somente o que esta em ios/docs/gds-v2-ios/<ARQUIVO-DO-PASSO>.

Regras:
1) Nao alterar backend.
2) Cumprir criterios de pronto e plano de testes do passo.
3) Trabalhar em worktree dedicado e branch dedicada do passo.
4) Atualizar ios/docs/gds-v2-ios/STATUS.md no inicio e no fim com:
   - status
   - resumo tecnico
   - branch/worktree
   - comandos de teste e resultado
5) Se houver bloqueio, registrar no STATUS.md e pausar.
6) Nao mover para Done sem testes passando.
```

## Checklist do orquestrador
1. Validar dependencias antes de liberar rodada.
2. Confirmar registro de inicio no `STATUS.md`.
3. Confirmar registro de testes por passo concluido.
4. Manter bloqueios explicitos com acao de destravamento.
5. So liberar proxima rodada apos gate satisfeito.

