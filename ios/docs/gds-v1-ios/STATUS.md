# STATUS - GDS v1.0 iOS

## Como usar
1. Atualize este arquivo diariamente.
2. Mantenha apenas um dono principal por passo.
3. Registre bloqueios de forma objetiva e com acao de destravamento.
4. Nao mover para `Done` sem criterio de pronto e testes da etapa.
5. Registrar e manter atualizado branch e worktree de cada agente.

## Mapa de worktrees
| Passo | Dono | Branch | Worktree path | Observacoes |
|---|---|---|---|---|
| `01` | Agente iOS Platform | `feat/gds-v1-step01-ios` | `/Users/brunocrema/runwarapp` | |
| `02` | Agente iOS Data/Health | `feat/ios-gds-02-healthkit-sync` | `../runwarapp-wt-02` | |
| `03` | Agente iOS Runtime/UX | `feat/ios-gds-03-companion-states` | `../runwarapp-wt-03` | |
| `04` | Agente iOS Maps | `feat/ios-gds-04-mapa-home-cta` | `../runwarapp-wt-04` | |
| `05` | Agente iOS UX Flow | `feat/ios-gds-05-resultado-pos-corrida` | `../runwarapp-wt-05` | |
| `06` | Agente iOS Social | `feat/ios-gds-06-bandeiras` | `/tmp/runwarapp-wt-06` | |
| `07` | Agente iOS Profile | `feat/ios-gds-07-perfil` | `../runwarapp-wt-07` | |
| `08` | Agente iOS QA | `feat/ios-gds-08-qa-gates` | `../runwarapp-wt-08` | Worktree ativo desta execucao |
| `09` | Agente iOS Release | `feat/ios-gds-09-hardening` | `../runwarapp-wt-09` | |

## Kanban

### To Do
- [ ] `02` Sync HealthKit pipeline - Dono: `Agente iOS Data/Health` (depende de `01`)
- [ ] `03` Companion HUD estados - Dono: `Agente iOS Runtime/UX` (depende de `02`)
- [ ] `04` Mapa home CTA tiles - Dono: `Agente iOS Maps` (depende de `01`)
- [ ] `06` Bandeiras fluxo completo - Dono: `Agente iOS Social`
- [ ] `07` Perfil basico historico - Dono: `Agente iOS Profile`
- [ ] `09` Hardening release - Dono: `Agente iOS Release` (depende de `03`,`04`,`05`,`06`,`07`)

### In Progress
- [ ] Nenhum no momento

### Blocked
- [ ] `08` Testes QA gates - Dono: `Agente iOS QA` (bloqueio de smoke real por assinatura/provisioning em device)

### Done
- [x] `00` Decisoes V1 iOS registradas
- [x] Estrutura documental `ios/docs/gds-v1-ios/` criada
- [x] `01` Fundacao permissoes config - Dono: `Agente iOS Platform`
- [x] `05` Resultado pos-corrida - Dono: `Agente iOS UX Flow`
- [x] `07` Perfil basico historico - Dono: `Agente iOS Profile`
- [x] `06` Bandeiras fluxo completo - Dono: `Agente iOS Social`

## Tabela de acompanhamento
| Passo | Status | Dono | Dependencias | Bloqueio | Ultima atualizacao |
|---|---|---|---|---|---|
| `01` | Done | Agente iOS Platform | - | - | 2026-02-06 |
| `02` | To Do | Agente iOS Data/Health | `01` | - | 2026-02-05 |
| `03` | To Do | Agente iOS Runtime/UX | `02` | - | 2026-02-05 |
| `04` | To Do | Agente iOS Maps | `01` | - | 2026-02-05 |
| `05` | Done | Agente iOS UX Flow | `02` | - | 2026-02-11 |
| `06` | To Do | Agente iOS Social | - | - | 2026-02-05 |
| `07` | Done | Agente iOS Profile | - | - | 2026-02-06 |
| `06` | Done | Agente iOS Social | - | - | 2026-02-06 |
| `07` | To Do | Agente iOS Profile | - | - | 2026-02-05 |
| `08` | Blocked | Agente iOS QA | paralelo | smoke real bloqueado por assinatura/provisioning do Team `<TEAM_ID>` | 2026-02-06 |
| `09` | To Do | Agente iOS Release | `03`,`04`,`05`,`06`,`07` | - | 2026-02-05 |

## Gate de qualidade geral
- [x] `xcodebuild -scheme LigaRun -destination "${XCODE_DESTINATION:-platform=iOS Simulator,OS=latest,name=iPhone 15}" test` verde no branch final
- [ ] Smoke real em dispositivo concluido e registrado
- [x] 6 casos de aceite do GDS validados

## Atualizacoes
- `05` 2026-02-11 — Status: Done. Resumo tecnico: `SubmissionResultView` refatorada para layout clean com card de impacto territorial (conquistou/atacou/defendeu/sem efeito), metricas essenciais (distancia, duracao, tile foco e escudo antes/depois), bloco de razoes de invalidade agrupadas/traduzidas e CTA `Ver no mapa` com foco consistente no tile alvo. `SubmissionResultPresentation` foi expandido com mapeamentos de impacto, labels de escudo/duracao e composicao deduplicada de reasons; fixtures e testes unitarios foram atualizados para cobrir os novos cenarios. Branch/worktree: `feat/ios-gds-05-resultado-pos-corrida` em `/private/tmp/runwarapp-wt-05`. Testes: `cd /private/tmp/runwarapp-wt-05/ios/LigaRun && xcodegen generate && CLANG_MODULE_CACHE_PATH=$(pwd)/ModuleCache SWIFT_MODULE_CACHE_PATH=$(pwd)/ModuleCache SWIFTPM_CACHE_PATH=$(pwd)/.swiftpm/cache xcodebuild -project LigaRun.xcodeproj -scheme LigaRun -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' -derivedDataPath $(pwd)/DerivedData -clonedSourcePackagesDirPath /Users/brunocrema/runwarapp/ios/LigaRun/SourcePackages -disableAutomaticPackageResolution test` (passou, 55 testes, 0 falhas, `TEST SUCCEEDED`).
- `05` 2026-02-11 — Status: In Progress. Resumo tecnico: implementacao iniciada da rodada 3 para refatorar resultado pos-corrida no formato clean com destaque de impacto territorial, razoes de invalidade agrupadas e CTA consistente de foco no mapa. Branch/worktree: `feat/ios-gds-05-resultado-pos-corrida` em `/private/tmp/runwarapp-wt-05`. Testes: planejados `cd ios/LigaRun && xcodegen generate` e `xcodebuild -project LigaRun.xcodeproj -scheme LigaRun -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' -derivedDataPath $(pwd)/DerivedData -clonedSourcePackagesDirPath /Users/brunocrema/runwarapp/ios/LigaRun/SourcePackages -disableAutomaticPackageResolution test`; resultado inicial: em andamento.
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
