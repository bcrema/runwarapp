# Codex Agent Guide — iOS

## Escopo
- App nativo em `ios/LigaRun/` (SwiftUI + Mapbox).
- Não alterar backend ou frontend aqui.

## Stack e comandos
- Projeto definido por `project.yml` (XcodeGen). Gere com:
  - `cd ios/LigaRun && xcodegen generate`
- Build/rodar pelo Xcode (`LigaRun.xcodeproj`).
- Mapbox via SPM; tokens em `Config/Debug.xcconfig` e `Config/Release.xcconfig`.

## Ambiente para compilar, testar e rodar
- **SO**: macOS 14+ (Sonoma ou superior).
- **Xcode**: 15.x com Command Line Tools instalados.
- **Ferramentas**: XcodeGen via Homebrew (`brew install xcodegen`).
- **Simulador**: iOS 17+ (ex.: iPhone 15) instalado no Xcode.
- **Build (CLI)**:
  - `cd ios/LigaRun && xcodegen generate`
  - `xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 15" build`
- **Testes (CLI)**:
  - `xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 15" test`
- **Rodar**:
  - Preferir pelo Xcode (Run no simulador/dispositivo); garantir o simulador iOS 17+ ativo.

## Padrões
- Manter SwiftUI/Combine simples; evitar mudar bundle id ou targets sem pedido.
- Atualize `configFiles` em `project.yml` se adicionar novas configs.
- Não exponha segredos; use xcconfig para valores.
- Sempre trabalhe em uma branch de feature separada da `main` e abra PR para revisão, evitando merges diretos.

## Testes
- Sempre garanta cobertura de testes e resultados passando para mudanças.
- Use simulador para smoke tests; se criar lógica, inclua testes Swift quando possível.

## Checklist rápida
- Rodou `xcodegen generate` após mexer no `project.yml`?
- Tokens/URLs seguem xcconfig (não hardcode)?
