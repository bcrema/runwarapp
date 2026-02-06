# GDS v1.0 iOS - Execucao Paralelizavel

## Visao geral
Este pacote organiza a entrega do GDS v1.0 iOS em passos independentes para execucao paralela por varios agentes.
Cada arquivo `01` a `09` representa um passo com escopo, entregaveis, arquivos impactados, testes e criterio de pronto.
Use `STATUS.md` para acompanhamento diario e `ONBOARDING-AGENTES.md` para copiar prompts de execucao por agente.

## Estrategia de paralelizacao (worktree)
1. Padrao obrigatorio: `1 agente = 1 branch = 1 worktree`.
2. Nao compartilhar a mesma branch entre agentes.
3. Nao executar dois agentes no mesmo diretorio de trabalho.
4. Registrar branch e path do worktree no `STATUS.md`.

## Ordem sugerida de execucao
1. Executar `00-decisoes-v1-ios.md` como referencia obrigatoria.
2. Iniciar em paralelo: `01`, `06`, `07`, `08`.
3. Depois de `01`, iniciar `02` e `04`.
4. Depois de `02`, iniciar `03` e `05`.
5. Fechar com `09` apos `03`, `04`, `05`, `06`, `07`.

## Matriz de paralelizacao
| Passo | Pode iniciar quando | Pode rodar em paralelo com |
|---|---|---|
| `01` Fundacao | imediato | `06`, `07`, `08` |
| `02` Sync HealthKit | apos `01` | `04` |
| `03` Companion HUD | apos `02` | `05` |
| `04` Mapa Home CTA | apos `01` | `02` |
| `05` Resultado Pos-corrida | apos `02` | `03` |
| `06` Bandeiras | imediato | `01`, `07`, `08` |
| `07` Perfil Basico | imediato | `01`, `06`, `08` |
| `08` Testes e QA | imediato (e evolutivo) | todos |
| `09` Hardening Release | apos `03`,`04`,`05`,`06`,`07` | nenhum (fase final) |

## Definicao de done global
1. Testes automatizados verdes no iOS (`xcodebuild ... test`).
2. Smoke real concluido em dispositivo fisico.
3. Criterios do `GDS v1.0 - iOS.md` atendidos.
4. Sem mudanca de backend como parte desta entrega.
5. PR em branch de feature, sem merge direto na `main`.

## Arquivos de coordenacao
1. `ios/docs/gds-v1-ios/STATUS.md`
2. `ios/docs/gds-v1-ios/ONBOARDING-AGENTES.md`
