# LigaRun iOS (SwiftUI + Mapbox)

App nativo iOS que consome o backend atual do LigaRun. Usa SwiftUI, Mapbox Maps (para o mapa hexagonal) e os mesmos endpoints usados no frontend web.

## Requisitos
- Xcode 15+ (Swift 6.0+)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) instalado (`brew install xcodegen`)
- Token Mapbox (mesmo usado no frontend) e URL do backend (`http://localhost:8080` em dev)

## Como gerar o projeto
1) Instale dependências do sistema (Xcode, XcodeGen).
2) Ajuste `Config/Debug.xcconfig` e `Config/Release.xcconfig` com `API_BASE_URL` e `MAPBOX_ACCESS_TOKEN`.
3) Gere o `.xcodeproj`:
   ```bash
   cd ios/LigaRun
   xcodegen generate
   ```
4) Abra `LigaRun.xcodeproj` no Xcode, selecione um simulador ou dispositivo e rode.

## Estrutura
- `project.yml`: definição do projeto (XcodeGen) com dependência Mapbox via SPM.
- `Config/*.xcconfig`: configuração de ambiente (API base e token Mapbox).
- `Sources/LigaRun`: código SwiftUI (App, networking, modelos, features).
- `Resources`: Info.plist e Assets (adicione ícones reais depois).

## Notas
- O app usa localização para centralizar e buscar tiles; autorize o uso de localização no simulador ou device.
- Ícones em `AppIcon.appiconset` estão como placeholders; substitua por imagens reais antes de publicar.
- Se quiser usar outro mecanismo para gerar o projeto, importe a pasta `Sources/LigaRun` como target SwiftUI padrão no Xcode.
