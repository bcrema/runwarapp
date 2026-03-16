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

## Testes
Para rodar os testes via CLI (macOS com Xcode instalado):
```bash
cd ios/LigaRun
./scripts/run-tests.sh
```

O script gera o projeto via `xcodegen`, fixa `DerivedData` e `SourcePackages` dentro da pasta do app, tenta selecionar um simulador iOS disponivel automaticamente e aceita overrides por variavel de ambiente.

Comandos mais usados:
```bash
# Suite completa no destino padrao.
./scripts/run-tests.sh

# Suite especifica.
XCODE_ONLY_TESTING=MapViewModelTests ./scripts/run-tests.sh

# Multiplas suites.
XCODE_ONLY_TESTING=MapViewModelTests,BandeirasViewModelTests ./scripts/run-tests.sh

# Reaproveitar pacotes SPM ja resolvidos e evitar nova resolucao.
XCODE_CLONED_SOURCE_PACKAGES_DIR_PATH=/path/to/SourcePackages \
XCODE_DISABLE_AUTOMATIC_PACKAGE_RESOLUTION=1 \
./scripts/run-tests.sh
```

Variaveis suportadas:
- `XCODE_DESTINATION`: override do destino do simulador/device.
- `XCODE_ONLY_TESTING`: lista separada por virgula (`MapViewModelTests`, `LigaRunTests/MapViewModelTests` etc.).
- `XCODE_DERIVED_DATA_PATH`: destino de `DerivedData`.
- `XCODE_CLONED_SOURCE_PACKAGES_DIR_PATH`: cache/checkouts do SPM.
- `XCODE_DISABLE_AUTOMATIC_PACKAGE_RESOLUTION=1`: usa apenas pacotes ja resolvidos.
- `XCODE_SKIP_GENERATE=1`: pula `xcodegen generate` quando o projeto ja estiver atualizado.

## Estrutura
- `project.yml`: definição do projeto (XcodeGen) com dependência Mapbox via SPM.
- `Config/*.xcconfig`: configuração de ambiente (API base e token Mapbox).
- `Sources/LigaRun`: código SwiftUI (App, networking, modelos, features).
- `Resources`: Info.plist e Assets (adicione ícones reais depois).

## Notas
- O app usa localização para centralizar e buscar tiles; autorize o uso de localização no simulador ou device.
- Ícones em `AppIcon.appiconset` estão como placeholders; substitua por imagens reais antes de publicar.
- Se quiser usar outro mecanismo para gerar o projeto, importe a pasta `Sources/LigaRun` como target SwiftUI padrão no Xcode.
