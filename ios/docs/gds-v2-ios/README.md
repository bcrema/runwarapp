# GDS v2.0 iOS - Migracao Quadras (Execucao Paralelizavel)

## Visao geral
Este pacote organiza a migracao iOS de `tiles` para `quadras` com pre-validacao local de elegibilidade competitiva (campeao/dono), envio em modo treino para casos inelegiveis e ajuste completo dos fluxos de mapa, corrida e resultado.

Cada arquivo `01` a `09` representa um passo com escopo fechado, entregaveis, arquivos impactados, testes e criterio de pronto.

Use:
1. `TAREFAS-AGENTES.md` como plano mestre de rodadas e dependencias.
2. `STATUS.md` para acompanhamento diario.
3. `ONBOARDING-AGENTES.md` para prompts operacionais por agente.

## Estrategia de paralelizacao (worktree)
1. Padrao obrigatorio: `1 agente = 1 branch = 1 worktree`.
2. Nao compartilhar a mesma branch entre agentes.
3. Nao executar dois agentes no mesmo diretorio.
4. Registrar branch e path do worktree no `STATUS.md`.

## Ordem sugerida de execucao
1. Ler e congelar decisoes em `00-decisoes-v2-ios.md`.
2. Rodada 1 em paralelo: `01`, `02`, `03`, `08`.
3. Rodada 2 apos `01` e `03`: `04`, `05`.
4. Rodada 3 apos `02` e `05`: `06`, `07`.
5. Fechar com `09` apos passos funcionais e QA.

## Matriz de paralelizacao
| Passo | Pode iniciar quando | Pode rodar em paralelo com |
|---|---|---|
| `01` Contrato e modelos quadra | imediato | `02`, `03`, `08` |
| `02` Mapa quadras | imediato | `01`, `03`, `08` |
| `03` Elegibilidade campeao/dono | imediato | `01`, `02`, `08` |
| `04` Companion modo competitivo/treino | apos `01`,`03` | `05` |
| `05` Pipeline sync/upload com modo | apos `01`,`03` | `04` |
| `06` Resultado pos-corrida quadras | apos `02`,`05` | `07` |
| `07` Refactor e limpeza legado | apos `02`,`06` | nenhum critico |
| `08` Testes e QA gates | imediato (e evolutivo) | todos |
| `09` Hardening release v2 | apos `04`,`05`,`06`,`07`,`08` | nenhum |

## Definicao de done global
1. Fluxo Mapa + Corrida + Resultado sem referencia funcional ativa a `tile`.
2. Pre-validacao local de campeao/dono ativa e consistente com regra definida.
3. Corrida inelegivel enviada em `TRAINING` e comunicada na UI.
4. Foco pos-resultado via `quadraId` funcional.
5. Testes automatizados iOS verdes no comando oficial:
   - `xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17,OS=26.2" test`

## Arquivos de coordenacao
1. `ios/docs/gds-v2-ios/TAREFAS-AGENTES.md`
2. `ios/docs/gds-v2-ios/STATUS.md`
3. `ios/docs/gds-v2-ios/ONBOARDING-AGENTES.md`
