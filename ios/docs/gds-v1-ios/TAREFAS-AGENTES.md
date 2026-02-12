<<<<<<< HEAD
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
=======
# Tarefas de Execucao por Agente - GDS v1.0 iOS

## Objetivo
Transformar o plano do `README.md` em tarefas operacionais para execucao paralela e sequencial dos agentes.

## Premissas obrigatorias
1. Cada agente trabalha em `1 branch de feature + 1 worktree`.
2. Nao alterar backend nesta entrega.
3. Atualizar `ios/docs/gds-v1-ios/STATUS.md` no inicio e no fim de cada passo.
4. Todo passo so vai para `Done` com testes da etapa executados e registrados.

## Rodadas de execucao

### Rodada 1 (paralela)
Pode iniciar imediatamente: `01`, `06`, `07`, `08`.

#### Agente iOS Platform (`01`)
1. Validar permissoes de Saude/localizacao no fluxo de corrida.
2. Garantir card de permissao em `RunsView` com CTA para Ajustes em negado/restrito.
3. Confirmar ausencia de segredos hardcoded fora de `Config/*.xcconfig`.
4. Registrar evidencias de teste unitario e smoke no `STATUS.md`.

#### Agente iOS Social (`06`)
1. Entregar criacao de bandeira com formulario completo.
2. Garantir `join/leave` com feedback de sucesso/erro e estado consistente.
3. Atualizar `session.currentUser` apos mudanca de bandeira.
4. Cobrir `create/join/leave` com testes unitarios e registrar no `STATUS.md`.

#### Agente iOS Profile (`07`)
1. Entregar stats basicas do perfil (corridas, distancia, tiles).
2. Exibir historico curto (5-10 corridas) com status territorial.
3. Garantir estado vazio legivel e sem regressao em salvar perfil/logout.
4. Registrar testes unitarios + validacao manual no `STATUS.md`.

#### Agente iOS QA (`08`) (evolutivo, paralelo a todos)
1. Manter matriz de testes por modulo atualizada.
2. Cobrir fluxos novos com testes unitarios (sync, companion, mapa, bandeiras, resultado).
3. Rodar suite padrao no simulador e registrar resultado.
4. Registrar bloqueio de smoke real (se existir) com causa e proximo passo.

### Rodada 2 (sequencial apos `01`)
Pode iniciar apos `01`: `02`, `04` (paralelos entre si).

#### Agente iOS Data/Health (`02`)
1. Implementar `HealthKitRunSyncProviding` e `SyncedWorkoutPayload`.
2. Ler workout+route do HealthKit e converter para `/api/runs/coordinates`.
3. Integrar submissao com fallback de retry no `RunSessionStore`.
4. Cobrir payload, timeout e erro de rede com testes unitarios.

#### Agente iOS Maps (`04`)
1. Entregar mapa como home com CTA fixo `Acompanhar corrida`.
2. Garantir estados de tile (neutro/dominado/disputa) consistentes.
3. Atualizar tiles apos submissao sem reiniciar app.
4. Cobrir refresh/foco de tile em testes de `MapViewModel`.

### Rodada 3 (sequencial apos `02`)
Pode iniciar apos `02`: `03`, `05` (paralelos entre si).

#### Agente iOS Runtime/UX (`03`)
1. Definir `CompanionSyncState` e transicoes deterministicas.
2. Implementar coordinator `RunSyncCoordinating` (stop -> sync -> upload -> resultado).
3. Atualizar `ActiveRunHUD` para estados de progresso e erro com retry.
4. Cobrir transicoes de estado e fluxo de erro com testes unitarios.

#### Agente iOS UX Flow (`05`)
1. Refatorar resultado pos-corrida para resumo clean e territorial.
2. Exibir razoes de invalidade de forma legivel (treino salvo sem efeito competitivo).
3. Garantir acao `Ver no mapa` com foco no tile correto.
4. Cobrir mapeamento de reasons e prioridade de `tileFocusId` em testes.

### Rodada Final (sequencial)
Pode iniciar apos `03`,`04`,`05`,`06`,`07`: `09`.

#### Agente iOS Release (`09`)
1. Rodar regressao funcional final de mapa, corridas, bandeiras e perfil.
2. Medir latencia de sync/upload/resultado e registrar valores.
3. Consolidar consistencia de textos/UX com GDS.
4. Rodar suite final, anexar evidencias e fechar checklist de aceite no PR.

## Regras de handoff entre rodadas
1. Nao liberar rodada seguinte sem passo dependencia marcado como `Done` no `STATUS.md`.
2. Todo handoff deve incluir:
   - resumo tecnico do que foi entregue;
   - comandos de teste executados e resultado;
   - riscos remanescentes (se houver);
   - branch e worktree usados.
3. Bugs bloqueantes encontrados no `09` devem reabrir o passo dono (`02` a `07`) com registro no `STATUS.md`.

## Checklist rapido diario (coordenacao)
1. Confirmar passos ativos da rodada atual.
2. Confirmar bloqueios e donos.
3. Confirmar testes executados nas ultimas 24h.
4. Replanejar apenas se houver bloqueio de dependencia.
>>>>>>> origin/master
