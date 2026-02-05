# 01 - Fundacao permissoes config

## Objetivo
- Dono sugerido: `Agente iOS Platform`.
- Garantir base de permissao e configuracao para HealthKit e localizacao no fluxo V1.

## Escopo
- Entregaveis:
  - Fluxo de permissao de Saude e localizacao funcional no app.
  - Card de permissao integrado na tela de corridas.
  - Validacao de ausencia de hardcode de segredos fora de `xcconfig`.
- Ajustes em runtime para estados `notDetermined`, `denied`, `restricted`, `authorized`.

## Fora de escopo
- App watchOS.
- Mudancas de regra de validacao no backend.
- Refactor visual completo de outras telas.

## Pre-requisitos
- Ler `ios/docs/gds-v1-ios/00-decisoes-v1-ios.md`.
- Ambiente iOS funcional (`xcodegen`, Xcode, simulador iPhone 17).

## Arquivos iOS impactados
- `ios/LigaRun/Resources/Info.plist`
- `ios/LigaRun/Config/Debug.xcconfig`
- `ios/LigaRun/Config/Release.xcconfig`
- `ios/LigaRun/Sources/LigaRun/Services/LocationManager.swift`
- `ios/LigaRun/Sources/LigaRun/Services/HealthKitAuthorizationStore.swift`
- `ios/LigaRun/Sources/LigaRun/Features/Runs/RunsView.swift`

## Tarefas detalhadas
1. Revisar e completar chaves de permissao em `Info.plist` para Saude e localizacao.
2. Expor o `HealthKitPermissionCard` na UI de `RunsView` com CTA apropriado.
3. Garantir fluxo para abrir Ajustes quando permissao estiver negada/restrita.
4. Validar que tokens/URL fiquem apenas em `Config/*.xcconfig`.
5. Revisar mensagem de erro para estados sem HealthKit disponivel.

## Criterios de pronto
1. Ao abrir o fluxo de corridas, permissao de Saude fica visivel e acionavel.
2. Estado negado/restrito possui CTA de recuperacao (Ajustes).
3. Nenhum segredo novo hardcoded em fontes Swift.
4. Build e testes unitarios sem regressao.

## Plano de testes
1. Unitario: estado de autorizacao no `HealthKitAuthorizationStore`.
2. Unitario/UI: exibicao condicional do card de permissao em `RunsView`.
3. Manual simulador: primeira execucao com permissao pendente.
4. Manual dispositivo real: permissao negada e retorno via Ajustes.
5. Caso mapeado GDS: `Permissoes negadas exibem fallback correto`.

## Riscos
- Diferencas de comportamento de permissao entre simulador e dispositivo real.
- Mudanca de texto/chave de permissao pode quebrar review da App Store se incompleta.

## Handoff para proximo passo
- Liberar `02-sync-healthkit-pipeline.md` e `04-mapa-home-cta-tiles.md`.
- Registrar checklist de permissao executado no PR.
