# STATUS - GDS v1.0 iOS

## Como usar
1. Atualize este arquivo diariamente.
2. Mantenha apenas um dono principal por passo.
3. Registre bloqueios de forma objetiva e com acao de destravamento.
4. Nao mover para `Done` sem criterio de pronto e testes da etapa.
5. Registrar e manter atualizado branch e worktree de cada agente.
6. Toda atualizacao de inicio/fim deve conter: `status`, `resumo tecnico`, `branch/worktree`, `comandos de teste e resultado`.
7. Nao liberar rodada seguinte sem dependencia em `Done` com testes registrados.

## Protocolo de delegacao (obrigatorio)
1. Inicio do passo:
   - `Status: In Progress`
   - `Resumo tecnico: escopo exato da rodada`
   - `Branch/worktree: branch + path`
   - `Testes: comando(s) planejado(s) e estado inicial`
2. Fim do passo:
   - `Status: Done` ou `Status: Blocked`
   - `Resumo tecnico: entregue ou bloqueio`
   - `Branch/worktree: branch + path`
   - `Testes: comando(s) executado(s) + resultado`
3. Se `Blocked`, pausar o passo e registrar causa + proximo passo de destravamento.

## Gate de rodadas (2026-02-11)
- Rodada 1: `01` Done (com testes), `06` Done (com testes), `07` Done (com testes), `08` Blocked (smoke real por assinatura/provisioning).
- Rodada 2: executada para `02` e `04` (dependencia `01` concluida com testes).
- Rodada 3: liberada para `03` e `05` (`02` concluido com testes em 2026-02-11).
- Rodada final: bloqueada ate `03`,`05`,`06`,`07` ficarem `Done` com testes (`04` ja concluido; `09` nao pode iniciar).

## Mapa de worktrees
| Passo | Dono | Branch | Worktree path | Observacoes |
|---|---|---|---|---|
| `01` | Agente iOS Platform | `feat/gds-v1-step01-ios` | `/Users/brunocrema/runwarapp` | |
| `02` | Agente iOS Data/Health | `feat/ios-gds-02-healthkit-sync` | `/tmp/runwarapp-wt-02` | Done com testes em 2026-02-11 |
| `03` | Agente iOS Runtime/UX | `feat/ios-gds-03-companion-states` | `../runwarapp-wt-03` | |
| `04` | Agente iOS Maps | `feat/ios-gds-04-mapa-home-cta` | `/tmp/runwarapp-wt-04` | Done com testes em 2026-02-11 |
| `05` | Agente iOS UX Flow | `feat/ios-gds-05-resultado-pos-corrida` | `../runwarapp-wt-05` | |
| `06` | Agente iOS Social | `feat/ios-gds-06-bandeiras` | `/tmp/runwarapp-wt-06` | |
| `07` | Agente iOS Profile | `feat/ios-gds-07-perfil` | `../runwarapp-wt-07` | |
| `08` | Agente iOS QA | `feat/ios-gds-08-qa-gates` | `../runwarapp-wt-08` | Worktree ativo desta execucao |
| `09` | Agente iOS Release | `feat/ios-gds-09-hardening` | `../runwarapp-wt-09` | |

## Kanban

### To Do
- [ ] `03` Companion HUD estados - Dono: `Agente iOS Runtime/UX` (depende de `02`)
- [ ] `05` Resultado pos-corrida - Dono: `Agente iOS UX Flow` (depende de `02`)
- [ ] `09` Hardening release - Dono: `Agente iOS Release` (depende de `03`,`04`,`05`,`06`,`07`)

### In Progress
- Nenhum passo em progresso nesta rodada.

### Blocked
- [ ] `08` Testes QA gates - Dono: `Agente iOS QA` (bloqueio de smoke real por assinatura/provisioning em device)

### Done
- [x] `00` Decisoes V1 iOS registradas
- [x] Estrutura documental `ios/docs/gds-v1-ios/` criada
- [x] `01` Fundacao permissoes config - Dono: `Agente iOS Platform`
- [x] `02` Sync HealthKit pipeline - Dono: `Agente iOS Data/Health`
- [x] `04` Mapa home CTA tiles - Dono: `Agente iOS Maps`
- [x] `06` Bandeiras fluxo completo - Dono: `Agente iOS Social`
- [x] `07` Perfil basico historico - Dono: `Agente iOS Profile`

## Tabela de acompanhamento
| Passo | Status | Dono | Dependencias | Bloqueio | Ultima atualizacao |
|---|---|---|---|---|---|
| `01` | Done | Agente iOS Platform | - | - | 2026-02-06 |
| `02` | Done | Agente iOS Data/Health | `01` | - | 2026-02-11 |
| `03` | To Do | Agente iOS Runtime/UX | `02` | - | 2026-02-05 |
| `04` | Done | Agente iOS Maps | `01` | - | 2026-02-11 |
| `05` | To Do | Agente iOS UX Flow | `02` | - | 2026-02-05 |
| `06` | Done | Agente iOS Social | - | - | 2026-02-06 |
| `07` | Done | Agente iOS Profile | - | - | 2026-02-06 |
| `08` | Blocked | Agente iOS QA | paralelo | smoke real bloqueado por assinatura/provisioning do Team `<TEAM_ID>` | 2026-02-06 |
| `09` | To Do | Agente iOS Release | `03`,`04`,`05`,`06`,`07` | - | 2026-02-05 |

## Gate de qualidade geral
- [x] `xcodebuild -scheme LigaRun -destination "${XCODE_DESTINATION:-platform=iOS Simulator,OS=latest,name=iPhone 15}" test` verde no branch final
- [ ] Smoke real em dispositivo concluido e registrado
- [x] 6 casos de aceite do GDS validados

## Atualizacoes
- `04` 2026-02-11 — Status: Done. Resumo tecnico: mapa home entregue com CTA fixo `Acompanhar corrida`, legenda de estados (neutro/dominado/disputado), refresh de tiles ao focar/retornar de aba e consistencia visual dos hexagonos; cobertura de `MapViewModel` ampliada para upsert no foco, refresh por bounds e contagem de estados. Branch/worktree: `feat/ios-gds-04-mapa-home-cta` em `/tmp/runwarapp-wt-04`. Testes: `/bin/bash -lc "cd /private/tmp/runwarapp-wt-04/ios/LigaRun && xcodegen generate && CLANG_MODULE_CACHE_PATH=$(pwd)/ModuleCache SWIFT_MODULE_CACHE_PATH=$(pwd)/ModuleCache SWIFTPM_CACHE_PATH=$(pwd)/.swiftpm/cache xcodebuild -project LigaRun.xcodeproj -scheme LigaRun -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' -derivedDataPath $(pwd)/DerivedData -clonedSourcePackagesDirPath /Users/brunocrema/runwarapp/ios/LigaRun/SourcePackages -disableAutomaticPackageResolution test"` (passou, 54 testes, 0 falhas, `TEST SUCCEEDED`).
- `02` 2026-02-11 — Status: Done. Resumo tecnico: pipeline de sync HealthKit entregue com `HealthKitRunSyncService`, suporte a origem `healthKit` no `RunSessionStore`, fallback de upload com recuperacao de payload sem pontos e persistencia para retry em timeout de rota; ajustes de concorrencia no upload/`RunsViewModel`; testes de `RunUploadService` expandidos para cenario de recovery e timeout. Branch/worktree: `feat/ios-gds-02-healthkit-sync` em `/tmp/runwarapp-wt-02`. Testes: `/bin/bash -lc "cd /private/tmp/runwarapp-wt-02/ios/LigaRun && xcodegen generate && CLANG_MODULE_CACHE_PATH=$(pwd)/ModuleCache SWIFT_MODULE_CACHE_PATH=$(pwd)/ModuleCache SWIFTPM_CACHE_PATH=$(pwd)/.swiftpm/cache xcodebuild -project LigaRun.xcodeproj -scheme LigaRun -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' -derivedDataPath $(pwd)/DerivedData -clonedSourcePackagesDirPath /Users/brunocrema/runwarapp/ios/LigaRun/SourcePackages -disableAutomaticPackageResolution test"` (passou, 53 testes, 0 falhas, `TEST SUCCEEDED`).
- `04` 2026-02-09 — Status: In Progress. Resumo tecnico: sessao paralela persistente reaberta para manter execucao independente (`/tmp/runwarapp-wt-04`, branch `feat/ios-gds-04-mapa-home-cta`, sessao `#55233`). Branch/worktree: `feat/ios-gds-04-mapa-home-cta` em `/tmp/runwarapp-wt-04`. Testes: nenhum executado nesta atualizacao de infraestrutura (validacao de contexto com `pwd` + `git rev-parse --abbrev-ref HEAD`).
- `02` 2026-02-09 — Status: In Progress. Resumo tecnico: sessao paralela persistente reaberta para manter execucao independente (`/tmp/runwarapp-wt-02`, branch `feat/ios-gds-02-healthkit-sync`, sessao `#80167`). Branch/worktree: `feat/ios-gds-02-healthkit-sync` em `/tmp/runwarapp-wt-02`. Testes: nenhum executado nesta atualizacao de infraestrutura (validacao de contexto com `pwd` + `git rev-parse --abbrev-ref HEAD`).
- `04` 2026-02-09 — Status: In Progress. Resumo tecnico: sessao paralela criada para execucao dedicada do passo (`/tmp/runwarapp-wt-04`, branch `feat/ios-gds-04-mapa-home-cta`, sessao `#35381`). Branch/worktree: `feat/ios-gds-04-mapa-home-cta` em `/tmp/runwarapp-wt-04`. Testes: nenhum executado nesta atualizacao de orquestracao (somente inicializacao de sessao).
- `02` 2026-02-09 — Status: In Progress. Resumo tecnico: sessao paralela criada para execucao dedicada do passo (`/tmp/runwarapp-wt-02`, branch `feat/ios-gds-02-healthkit-sync`, sessao `#66189`). Branch/worktree: `feat/ios-gds-02-healthkit-sync` em `/tmp/runwarapp-wt-02`. Testes: nenhum executado nesta atualizacao de orquestracao (somente inicializacao de sessao).
- `04` 2026-02-09 — Status: In Progress. Resumo tecnico: rodada 2 iniciada para entregar mapa home com CTA fixo `Acompanhar corrida`, consistencia de estados de tile e refresh pos-submissao; dependencias validadas (`01` Done com testes). Branch/worktree: `feat/ios-gds-04-mapa-home-cta` em `../runwarapp-wt-04`. Testes: planejados para fechamento do passo com `cd ios/LigaRun && xcodegen generate` e `xcodebuild -scheme LigaRun -destination "${XCODE_DESTINATION:-platform=iOS Simulator,OS=latest,name=iPhone 15}" test`; resultado inicial: nao executado neste inicio.
- `02` 2026-02-09 — Status: In Progress. Resumo tecnico: rodada 2 iniciada para implementar pipeline HealthKit (`HealthKitRunSyncProviding`, payload sincronizado e fallback de retry no `RunSessionStore`); dependencias validadas (`01` Done com testes). Branch/worktree: `feat/ios-gds-02-healthkit-sync` em `../runwarapp-wt-02`. Testes: planejados para fechamento do passo com `cd ios/LigaRun && xcodegen generate` e `xcodebuild -scheme LigaRun -destination "${XCODE_DESTINATION:-platform=iOS Simulator,OS=latest,name=iPhone 15}" test`; resultado inicial: nao executado neste inicio.
- `08` 2026-02-06 — Status: Blocked. Resumo: matriz de testes e gate de merge entregues (novos testes para sync/submissao, companion, mapa, bandeiras e resultado; script padrao atualizado; documentacao do passo 08 atualizada). Smoke real em device bloqueado por assinatura/provisioning. Branch/worktree: `feat/ios-gds-08-qa-gates` em `../runwarapp-wt-08`. Testes: `cd ios/LigaRun && xcodegen generate` (passou); `xcodebuild -scheme LigaRun -destination "${XCODE_DESTINATION:-platform=iOS Simulator,OS=latest,name=iPhone 15}" test` (passou, 45 testes); `xcrun xctrace list devices` (passou, device `<DEVICE_ID>` detectado); `xcodebuild -scheme LigaRun -destination "platform=iOS,id=<DEVICE_ID>" test` (falhou: development team nao configurado); `xcodebuild -scheme LigaRun -destination "platform=iOS,id=<DEVICE_ID>" test DEVELOPMENT_TEAM=<TEAM_ID> CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates -allowProvisioningDeviceRegistration` (falhou: No Account for Team + sem certificado/perfil). Proximo passo: configurar DEVELOPMENT_TEAM com conta valida e perfis/certificados no Xcode e repetir os testes em device real.
- `07` 2026-02-06 — Status: Done. Resumo: perfil agora exibe bloco de stats basicas (corridas, distancia total e tiles conquistados) e historico curto (limite 10) com status valido/invalido e acao territorial, incluindo estado vazio legivel; fluxo de salvar alteracoes/logout preservado. Cobertura unitária do perfil adicionada em arquivo incluído no target (`ProfileViewModelTests`). Branch/worktree: `feat/ios-gds-07-perfil` em `../runwarapp-wt-07`. Testes: `CLANG_MODULE_CACHE_PATH=$(pwd)/ModuleCache SWIFT_MODULE_CACHE_PATH=$(pwd)/ModuleCache SWIFTPM_CACHE_PATH=$(pwd)/.swiftpm/cache xcodebuild -project LigaRun.xcodeproj -scheme LigaRun -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' -derivedDataPath $(pwd)/DerivedData -clonedSourcePackagesDirPath /Users/brunocrema/runwarapp/ios/SourcePackages test` (passou, 29 testes).
- `07` 2026-02-06 — Status: In Progress. Resumo: passo iniciado para entregar stats basicas e historico curto no perfil com cobertura de testes e validacao de regressao em salvar perfil/logout. Branch/worktree: `feat/ios-gds-07-perfil` em `../runwarapp-wt-07`. Testes: em andamento.
- `06` 2026-02-06 — Status: Done. Resumo: fluxo completo de bandeiras finalizado com criacao via formulario (nome/categoria/cor/descricao), entrar/sair com feedback de sucesso e mensagem de impacto nas acoes futuras, estados vazio/erro recuperaveis de busca/lista e sincronizacao de estado apos join/leave. Cobertura de testes adicionada para `join`, `leave`, criacao com sucesso e erro (`BandeirasViewModelTests`), `RunsViewModelTests` reativado no target e corrigido, e `project.yml` ajustado para preservar chaves de permissao no `Info.plist` apos regeneracao do projeto. Branch: `feat/ios-gds-06-bandeiras`. Worktree: `/tmp/runwarapp-wt-06`. Testes: `xcodebuild -project LigaRun.xcodeproj -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17,OS=26.2" -derivedDataPath /Users/brunocrema/runwarapp/ios/LigaRun/DerivedData -clonedSourcePackagesDirPath /Users/brunocrema/runwarapp/ios/LigaRun/SourcePackages -disableAutomaticPackageResolution test` (passou; 31 testes, 0 falhas); `xcodebuild` retries anteriores durante a retomada (falharam por erros de compilacao de testes, corrigidos); `xcodegen generate` (passou; incluiu `BandeirasViewModelTests.swift` e `RunsViewModelTests.swift` no target de testes).
- `06` 2026-02-06 — Status: In Progress. Resumo: bloqueio de espaco em disco removido; retomada de execucao de testes do passo 06 para validar entrega final. Branch: `feat/ios-gds-06-bandeiras`. Worktree: `/tmp/runwarapp-wt-06`. Testes: em andamento.
- `06` 2026-02-06 — Status: Blocked. Resumo: entregue fluxo completo de bandeiras no iOS com criacao (formulario nome/categoria/cor/descricao), entrar/sair com feedback de sucesso, mensagem de impacto nas acoes futuras, estados vazio/erro recuperaveis, sincronizacao de `session.currentUser` apos mudanca e novos testes unitarios de `BandeirasViewModel` para `join/leave/create` (sucesso/erro). Branch: `feat/ios-gds-06-bandeiras`. Worktree: `/tmp/runwarapp-wt-06`. Testes: `xcodebuild -project LigaRun.xcodeproj -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17,OS=26.2" -derivedDataPath /tmp/runwarapp-wt-06/DerivedData -clonedSourcePackagesDirPath /tmp/runwarapp-wt-06/SourcePackages test` (falhou: CoreSimulator indisponivel + sem rede para SPM); `xcodebuild -project LigaRun.xcodeproj -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17,OS=26.2" -derivedDataPath /tmp/runwarapp-wt-06/DerivedData -clonedSourcePackagesDirPath /Users/brunocrema/runwarapp/ios/LigaRun/SourcePackages -disableAutomaticPackageResolution test` (falhou: sandbox/CoreSimulator); `/bin/bash -lc "cd /tmp/runwarapp-wt-06/ios/LigaRun && CLANG_MODULE_CACHE_PATH=$(pwd)/ModuleCache SWIFT_MODULE_CACHE_PATH=$(pwd)/ModuleCache SWIFTPM_CACHE_PATH=$(pwd)/.swiftpm/cache xcodebuild -project LigaRun.xcodeproj -scheme LigaRun -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' -derivedDataPath $(pwd)/DerivedData -clonedSourcePackagesDirPath /Users/brunocrema/runwarapp/ios/LigaRun/SourcePackages -disableAutomaticPackageResolution test"` (falhou: `No space left on device` durante build, testes cancelados).
- `06` 2026-02-06 — Status: In Progress. Resumo: inicio do passo 06 com branch/worktree dedicados e levantamento de implementacao para fluxo completo de bandeiras (criar/entrar/sair + estados de erro/vazio). Branch: `feat/ios-gds-06-bandeiras`. Worktree: `/tmp/runwarapp-wt-06`. Testes: em andamento.
- `01` 2026-02-06 — Status: Done. Resumo: fluxo de permissoes (Saude/localizacao) com card na tela de corridas validado; logica de autorizacao ajustada para refletir leitura real e CTA de Ajustes. Testes: `xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17" test` (passou - informado pelo usuario); manual dispositivo (permissoes corridas) (passou).
- `01` 2026-02-06 — Status: Blocked. Resumo: reteste manual do card de permissao concluido com sucesso (3 passos). Aguardando confirmacao de testes unitarios/build. Testes: manual (permissoes corridas) (passou).
- `01` 2026-02-06 — Status: Blocked. Resumo: ajuste de deteccao de autorizacao HealthKit para considerar amostra real de workout (evita falso autorizado quando acesso negado) e texto do card atualizado para refletir ausencia de dados. Testes: `xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17,OS=26.2" test` (falhou: sem projeto no cwd); `/bin/bash -lc "cd /Users/brunocrema/runwarapp/ios/LigaRun && CLANG_MODULE_CACHE_PATH=$(pwd)/ModuleCache SWIFT_MODULE_CACHE_PATH=$(pwd)/ModuleCache SWIFTPM_CACHE_PATH=$(pwd)/.swiftpm/cache xcodebuild -project LigaRun.xcodeproj -scheme LigaRun -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' -derivedDataPath $(pwd)/DerivedData -clonedSourcePackagesDirPath $(pwd)/SourcePackages test"` (falhou: CoreSimulator indisponivel + sem rede para SPM).
- `01` 2026-02-06 — Status: In Progress. Resumo: retomando investigacao do card de permissao (Passo 3) que nao aparece em alguns fluxos; preparando ajuste e reteste. Testes: em andamento.
- `01` 2026-02-06 — Status: In Progress. Resumo: trocada deteccao de autorizacao HealthKit para query de leitura (hasReadAuthorization) e testes atualizados. Testes: `xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17,OS=26.2" test` (passou).
- `01` 2026-02-06 — Status: Blocked. Resumo: ajustada logica de status para nao marcar autorizado quando requestStatus e unnecessary + sharingDenied; testes passaram, aguardando reteste manual de negado/Ajustes. Testes: `xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17,OS=26.2" test` (passou).
- `01` 2026-02-06 — Status: In Progress. Resumo: card de permissao Saude apareceu e, apos autorizar, desapareceu; falta validar fluxo negado/Ajustes. Testes: manual dispositivo (autorizado passou).
- `01` 2026-02-06 — Status: Blocked. Resumo: logica de status HealthKit ajustada para leitura (requestStatus + flag de solicitacao) e refresh async no RunsView; testes unitarios passaram, aguardando reteste manual do card de permissao. Testes: `xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17,OS=26.2" test` (passou).
- `01` 2026-02-06 — Status: In Progress. Resumo: ajustando logica de status do HealthKit para refletir autorizacao de leitura e reexibir card corretamente. Testes: em andamento.
- `01` 2026-02-06 — Status: Blocked. Resumo: teste manual indicou que o card de permissao Saude nao aparece no fluxo de corridas e o acesso falhou. Testes: manual dispositivo (falhou).
- `01` 2026-02-05 — Status: Blocked. Resumo: xcodebuild ainda nao reconhece a conta do team Z76YM922M4 e nao encontra provisioning/certificado, apesar da identidade no keychain. Testes: `xcodebuild -scheme LigaRun -destination "platform=iOS,id=00008120-0019186926C2201E" test DEVELOPMENT_TEAM=Z76YM922M4 CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates -allowProvisioningDeviceRegistration` (falhou: No Account for Team + no profiles + no signing certificate).
- `01` 2026-02-05 — Status: In Progress. Resumo: identidade de assinatura confirmada; retomando testes em device. Testes: em andamento.
- `01` 2026-02-05 — Status: Blocked. Resumo: ambiente CLI nao encontra identidades de assinatura no keychain (`security find-identity -p codesigning -v` retornou 0). Testes: `security find-identity -p codesigning -v` (0 identidades).
- `01` 2026-02-05 — Status: Blocked. Resumo: novo retry no device falhou; xcodebuild segue sem conta do team Z76YM922M4 e sem provisioning/certificado. Testes: `xcodebuild -scheme LigaRun -destination "platform=iOS,id=00008120-0019186926C2201E" test DEVELOPMENT_TEAM=Z76YM922M4 CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates -allowProvisioningDeviceRegistration` (falhou: No Account for Team + no profiles + no signing certificate).
- `01` 2026-02-05 — Status: In Progress. Resumo: retomando testes em device apos build no Xcode. Testes: em andamento.
- `01` 2026-02-05 — Status: Blocked. Resumo: tentativa novamente no device falhou; xcodebuild segue sem conta do team Z76YM922M4 e sem provisioning/certificado. Testes: `xcodebuild -scheme LigaRun -destination "platform=iOS,id=00008120-0019186926C2201E" test DEVELOPMENT_TEAM=Z76YM922M4 CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates -allowProvisioningDeviceRegistration` (falhou: No Account for Team + no profiles + no signing certificate).
- `01` 2026-02-05 — Status: In Progress. Resumo: retomando testes em dispositivo apos ajuste de conta/certificados. Testes: em andamento.
- `01` 2026-02-05 — Status: Blocked. Resumo: xcodebuild ainda nao encontra conta do team Z76YM922M4 e nao acha provisioning/certificado. Testes: `xcodebuild -scheme LigaRun -destination "platform=iOS,id=00008120-0019186926C2201E" test DEVELOPMENT_TEAM=Z76YM922M4 CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates -allowProvisioningDeviceRegistration` (falhou: No Account for Team + no profiles + no signing certificate).
- `01` 2026-02-05 — Status: In Progress. Resumo: retomando testes em dispositivo apos ajuste de login/assinatura. Testes: em andamento.
- `01` 2026-02-05 — Status: Blocked. Resumo: teste em dispositivo falhou novamente; Xcode segue rejeitando login do Apple ID e nao encontra provisioning/certificado. Testes: `xcodebuild -scheme LigaRun -destination "platform=iOS,id=00008120-0019186926C2201E" test DEVELOPMENT_TEAM=Z76YM922M4 CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates -allowProvisioningDeviceRegistration` (falhou: login rejeitado + no profiles + no signing certificate).
- `01` 2026-02-05 — Status: In Progress. Resumo: retomando testes em dispositivo com perfil Xcode managed. Testes: em andamento.
- `01` 2026-02-05 — Status: Blocked. Resumo: tentativa de provisionamento automatico falhou por login Apple ID rejeitado e ausencia de certificado/provisioning. Testes: `xcodebuild -scheme LigaRun -destination "platform=iOS,id=00008120-0019186926C2201E" test DEVELOPMENT_TEAM=Z76YM922M4 CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates -allowProvisioningDeviceRegistration` (falhou: login rejeitado + no profiles + no signing certificate).
- `01` 2026-02-05 — Status: In Progress. Resumo: retomando testes em dispositivo com provisioning/assinatura automatica. Testes: em andamento.
- `01` 2026-02-05 — Status: Blocked. Resumo: teste em dispositivo falhou por ausencia de provisioning profile e certificado iOS Development do team Z76YM922M4. Testes: `xcodebuild -scheme LigaRun -destination "platform=iOS,id=00008120-0019186926C2201E" test DEVELOPMENT_TEAM=Z76YM922M4` (falhou: no profiles + no signing certificate).
- `01` 2026-02-05 — Status: In Progress. Resumo: tentando testes em dispositivo com Development Team informado. Testes: em andamento.
- `01` 2026-02-05 — Status: Blocked. Resumo: tentativa de testes em dispositivo falhou por falta de Development Team para assinatura do target de testes. Testes: `xcodebuild -scheme LigaRun -destination "platform=iOS,id=00008120-0019186926C2201E" test` (falhou: Signing for "LigaRunTests" requires a development team).
- `01` 2026-02-05 — Status: In Progress. Resumo: iniciando testes manuais/dispositivo real. Testes: em andamento.
- `01` 2026-02-05 — Status: Blocked. Resumo: testes automatizados passaram; pendentes testes manuais em simulador e dispositivo real para criterios de pronto. Testes: `xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17,OS=26.2" test` (passou).
- `01` 2026-02-05 — Status: Blocked. Resumo: adicionadas chaves de permissao (HealthKit/localizacao) no Info.plist e card de permissao do Saude integrado em `RunsView`, com CTA para Ajustes e refresh ao voltar do background; cobertura unitária para exibicao condicional do card. Testes: `xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 15" test` (falhou: destino iPhone 15 indisponivel); `xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17,OS=26.2" test` (falhou: CoreSimulatorService indisponivel + restricoes de permissao em DerivedData/ModuleCache).
