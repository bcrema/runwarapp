# STATUS - GDS v1.0 iOS

## Como usar
1. Atualize este arquivo diariamente.
2. Mantenha apenas um dono principal por passo.
3. Registre bloqueios de forma objetiva e com acao de destravamento.
4. Nao mover para `Done` sem criterio de pronto e testes da etapa.

## Kanban

### To Do
- [ ] `01` Fundacao permissoes config - Dono: `Agente iOS Platform`
- [ ] `02` Sync HealthKit pipeline - Dono: `Agente iOS Data/Health` (depende de `01`)
- [ ] `03` Companion HUD estados - Dono: `Agente iOS Runtime/UX` (depende de `02`)
- [ ] `04` Mapa home CTA tiles - Dono: `Agente iOS Maps` (depende de `01`)
- [ ] `05` Resultado pos-corrida - Dono: `Agente iOS UX Flow` (depende de `02`)
- [ ] `06` Bandeiras fluxo completo - Dono: `Agente iOS Social`
- [ ] `07` Perfil basico historico - Dono: `Agente iOS Profile`
- [ ] `08` Testes QA gates - Dono: `Agente iOS QA` (evolutivo)
- [ ] `09` Hardening release - Dono: `Agente iOS Release` (depende de `03`,`04`,`05`,`06`,`07`)

### In Progress
- [ ] Nenhum no momento

### Blocked
- [ ] Nenhum no momento

### Done
- [x] `00` Decisoes V1 iOS registradas
- [x] Estrutura documental `ios/docs/gds-v1-ios/` criada

## Tabela de acompanhamento
| Passo | Status | Dono | Dependencias | Bloqueio | Ultima atualizacao |
|---|---|---|---|---|---|
| `01` | To Do | Agente iOS Platform | - | - | 2026-02-05 |
| `02` | To Do | Agente iOS Data/Health | `01` | - | 2026-02-05 |
| `03` | To Do | Agente iOS Runtime/UX | `02` | - | 2026-02-05 |
| `04` | To Do | Agente iOS Maps | `01` | - | 2026-02-05 |
| `05` | To Do | Agente iOS UX Flow | `02` | - | 2026-02-05 |
| `06` | To Do | Agente iOS Social | - | - | 2026-02-05 |
| `07` | To Do | Agente iOS Profile | - | - | 2026-02-05 |
| `08` | To Do | Agente iOS QA | paralelo | - | 2026-02-05 |
| `09` | To Do | Agente iOS Release | `03`,`04`,`05`,`06`,`07` | - | 2026-02-05 |

## Gate de qualidade geral
- [ ] `xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17" test` verde no branch final
- [ ] Smoke real em dispositivo concluido e registrado
- [ ] 6 casos de aceite do GDS validados
