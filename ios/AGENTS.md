# Codex Agent Guide — iOS

## Escopo
- App nativo em `ios/LigaRun/` (SwiftUI + Mapbox).
- Não alterar backend ou frontend aqui.

## Stack e comandos
- Projeto definido por `project.yml` (XcodeGen). Gere com:
  - `cd ios/LigaRun && xcodegen generate`
- Build/rodar pelo Xcode (`LigaRun.xcodeproj`).
- Mapbox via SPM; tokens em `Config/Debug.xcconfig` e `Config/Release.xcconfig`.

## Padrões
- Manter SwiftUI/Combine simples; evitar mudar bundle id ou targets sem pedido.
- Atualize `configFiles` em `project.yml` se adicionar novas configs.
- Não exponha segredos; use xcconfig para valores.

## Testes
- Use simulador para smoke tests; se criar lógica, inclua testes Swift quando possível.

## Checklist rápida
- Rodou `xcodegen generate` após mexer no `project.yml`?
- Tokens/URLs seguem xcconfig (não hardcode)?
