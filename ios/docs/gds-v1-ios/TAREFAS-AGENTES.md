# Tarefas de Agentes - Plano Mestre (GDS v1.0 iOS)

## Objetivo
Este arquivo e a referencia oficial de delegacao por rodadas para a entrega do GDS v1.0 iOS.
Use este plano para decidir o que pode iniciar, o que deve pausar e quando liberar a rodada seguinte.

## Regras obrigatorias
1. Ler antes de codar:
   - `ios/docs/gds-v1-ios/00-decisoes-v1-ios.md`
   - `ios/docs/gds-v1-ios/README.md`
   - `ios/docs/gds-v1-ios/STATUS.md`
2. Trabalhar somente no passo atribuido.
3. Nao alterar backend.
4. Padrao obrigatorio: `1 agente = 1 passo = 1 branch = 1 worktree`.
5. Se houver bloqueio, registrar no `STATUS.md` e pausar o passo imediatamente.
6. Nao marcar `Done` sem testes executados e resultado registrado no `STATUS.md`.
7. Nao liberar rodada seguinte sem dependencias em `Done` com testes.

## Contrato de atualizacao do STATUS.md (inicio e fim)
Toda atualizacao de inicio/fim de passo deve conter:
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

## Rodadas e gates de dependencia
| Rodada | Passos | Gate para iniciar | Gate para liberar a proxima rodada |
|---|---|---|---|
| `1` | `01`, `06`, `07`, `08` | imediato | `01` em `Done` com testes para liberar rodada `2` |
| `2` | `02`, `04` | `01` em `Done` com testes | `02` em `Done` com testes para liberar rodada `3` |
| `3` | `03`, `05` | `02` em `Done` com testes | `03` e `05` em `Done` com testes para liberar rodada final |
| `Final` | `09` | `03`,`04`,`05`,`06`,`07` em `Done` com testes | encerramento da execucao |

## Prompt base para delegacao
```text
Voce e o dono do passo <PASSO>. Execute somente o que esta em ios/docs/gds-v1-ios/<ARQUIVO-DO-PASSO>.

Regras:
1) Nao alterar backend.
2) Cumprir criterios de pronto e plano de testes do passo.
3) Trabalhar em worktree dedicado e branch dedicada do passo.
4) Atualizar ios/docs/gds-v1-ios/STATUS.md no inicio e no fim com:
   - status
   - resumo tecnico
   - branch/worktree
   - comandos de teste e resultado
5) Se houver bloqueio, registrar no STATUS.md e pausar o passo.
6) Nao mover para Done sem testes passando.
```

## Checklist do orquestrador por rodada
1. Validar dependencias no `STATUS.md` antes de liberar a rodada.
2. Confirmar que cada passo da rodada foi iniciado com registro completo no `STATUS.md`.
3. Confirmar que cada passo concluido registrou testes com resultado.
4. Manter passos bloqueados explicitamente em `Blocked` com acao de destravamento.
5. So liberar proxima rodada apos gate satisfeito (`Done` + testes nas dependencias).
