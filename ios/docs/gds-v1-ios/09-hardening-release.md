# 09 - Hardening release

## Objetivo
- Dono sugerido: `Agente iOS Release`.
- Consolidar estabilidade, performance e consistencia de UX antes da entrega V1.

## Escopo
- Entregaveis:
  - Checklist final de regressao funcional.
  - Validacao de performance/latencia do fluxo sync -> upload -> resultado.
  - Revisao final de strings e consistencia de UX com GDS.
  - Pacote de evidencias para PR final.

## Fora de escopo
- Novos features fora do GDS V1.
- Mudancas de backend ou migrações de schema.

## Pre-requisitos
- Conclusao de `03`, `04`, `05`, `06`, `07`.
- Relatorio de `08-testes-qa-gates.md` disponivel.

## Arquivos iOS impactados
- `ios/LigaRun/Sources/LigaRun/**` (ajustes finais pontuais)
- `ios/LigaRun/Tests/LigaRunTests/**` (fixes de estabilidade)
- `ios/LigaRun/README.md` (comandos finais, se necessario)
- `ios/docs/gds-v1-ios/*.md` (status final e evidencias)

## Tarefas detalhadas
1. Rodar checklist de regressao em fluxos principais (mapa, corridas, bandeiras, perfil).
2. Medir latencia de upload/validacao em rede estavel e registrar valores.
3. Revisar consistencia de textos de erro/sucesso com terminologia do GDS.
4. Garantir que nao haja warnings criticos ou crashes conhecidos.
5. Executar suite final:
   - `cd ios/LigaRun && xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 17" test`
6. Consolidar evidencias:
   - screenshots principais;
   - logs de smoke real;
   - resumo de criterios de aceite.

## Criterios de pronto
1. Regressao funcional fechada sem bloqueios P0/P1.
2. Suite de testes verde.
3. Smoke real concluido e documentado.
4. Criterios do GDS V1 iOS marcados como atendidos.
5. PR final pronto para revisao.

## Plano de testes
1. Repetir os 6 casos de aceite do passo `08`.
2. Rodar smoke de ponta a ponta no fluxo principal:
   - Fitness/Saude -> sync -> validacao -> territorio -> mapa.
3. Validar cenarios de erro:
   - sem permissao;
   - sem rede;
   - corrida invalida.

## Riscos
- Ajustes finais podem introduzir regressao tardia.
- Dependencia de ambiente real para validar latencia e HealthKit.

## Handoff para proximo passo
- Encerrar com PR final e checklist de aceite anexado.
- Se houver bloqueio critico, reabrir etapa responsavel (`02` a `07`) com bug especifico.

## Entrega executada (2026-02-11)

### Regressao funcional (rodada final)
| Fluxo | Evidencia | Status |
|---|---|---|
| Corrida + sync + upload + resultado | `RunSyncCoordinatorTests`, `RunUploadServiceTests`, `SubmissionResultPresentationTests` | OK |
| Mapa + tiles + foco de resultado | `MapViewModelTests` + foco por `tileFocusId` | OK |
| Bandeiras (create/join/leave) | `BandeirasViewModelTests` | OK |
| Perfil (stats + historico) | `ProfileViewModelTests` | OK |
| Permissoes/fallback | `HealthKitAuthorizationStoreTests` | OK |

### Latencia observada (ambiente de teste)
- `RunSyncCoordinatorTests`: cenarios entre ~`0.010s` e `0.025s` por caso.
- `RunUploadServiceTests`: cenarios entre ~`0.037s` e `0.087s` por caso.
- Observacao: sao tempos de ambiente controlado (mocks/stubs), servem como baseline tecnica, nao substituem medicao em rede real/dispositivo.

### Consistencia de UX/strings
- Mensagens de sucesso/erro do fluxo pos-corrida revisadas em `SubmissionResultPresentation`.
- Razoes de invalidade deduplicadas e traduzidas mantidas no resumo final.
- CTA de retorno ao mapa (`Ver no mapa`) preservado com foco consistente no tile.

### Suite final executada
- Comando:
  - `cd /tmp/runwarapp-wt-09/ios/LigaRun && xcodegen generate && CLANG_MODULE_CACHE_PATH=$(pwd)/ModuleCache SWIFT_MODULE_CACHE_PATH=$(pwd)/ModuleCache SWIFTPM_CACHE_PATH=$(pwd)/.swiftpm/cache xcodebuild -project LigaRun.xcodeproj -scheme LigaRun -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' -derivedDataPath $(pwd)/DerivedData -clonedSourcePackagesDirPath /Users/brunocrema/runwarapp/ios/LigaRun/SourcePackages -disableAutomaticPackageResolution test`
- Resultado: `TEST SUCCEEDED` (`62` testes, `0` falhas).
- Evidencia de execucao: `/tmp/runwarapp-wt-09/ios/LigaRun/DerivedData/Logs/Test/Test-LigaRun-2026.02.11_13-41-27--0300.xcresult`.

### Bloqueio para conclusao
- Smoke real em dispositivo segue bloqueado por assinatura/provisioning (`Team <TEAM_ID>`), mesmo impeditivo registrado no passo `08`.
- Decisao do passo: manter `09` em `Blocked` ate desbloqueio de conta/certificado/perfil para rodar smoke real.
