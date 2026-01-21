# LigaRun

🏃 Um jogo de conquista territorial no mundo real para corredores.

## Sobre

LigaRun transforma corridas em batalhas épicas. Corredores conquistam tiles hexagonais em Curitiba através de loops GPS válidos, defendem seu território e competem por bandeiras (assessorias, academias, boxes).

## Arquitetura

```
runwarapp/
├── backend/          # Kotlin + Spring Boot
│   ├── src/
│   │   └── main/kotlin/com/runwar/
│   │       ├── config/       # Security, JWT, CORS
│   │       ├── domain/       # User, Bandeira, Tile, Run
│   │       ├── game/         # H3Grid, LoopValidator, ShieldMechanics
│   │       ├── geo/          # GPX Parser
│   │       └── notification/ # Notificações
│   └── README.md
├── frontend/         # Next.js + TypeScript
│   ├── src/
│   │   ├── app/
│   │   ├── components/
│   │   └── lib/
│   └── README.md
├── ios/              # App iOS nativo (SwiftUI + Mapbox)
│   └── LigaRun/
│       ├── project.yml
│       └── README.md
└── docker-compose.yml
```

## Quick Start

### 1. Iniciar banco de dados

```bash
docker-compose up -d db
```

### 2. Backend

```bash
cd backend
./gradlew bootRun
```

O backend estará em http://localhost:8080
Swagger UI: http://localhost:8080/swagger-ui.html

### 3. Frontend

```bash
cd frontend
npm install
npm run dev
```

O frontend estará em http://localhost:3000

### 4. Mapbox Token

Para o mapa funcionar, obtenha um token em https://www.mapbox.com/ e configure:

```bash
# frontend/.env.local
NEXT_PUBLIC_MAPBOX_TOKEN=seu_token_aqui
```

### 5. iOS (MVP nativo)

O app iOS nativo vive em `ios/LigaRun/` (SwiftUI + Mapbox), consumindo o mesmo backend. Para gerar o projeto:

```bash
cd ios/LigaRun
# configure API_BASE_URL e MAPBOX_ACCESS_TOKEN em Config/*.xcconfig
xcodegen generate
open LigaRun.xcodeproj
```

## Regras do Jogo

| Ação | Efeito |
|------|--------|
| Conquista (tile neutro) | Escudo = 100 |
| Ataque (tile rival) | Escudo -35 |
| Defesa (seu tile) | Escudo +20 |
| Troca de dono | Escudo = 65, Cooldown 18h |
| Em disputa | Escudo < 70 |

### Loop Válido

- Distância mínima: 1.2 km
- Duração mínima: 7 minutos
- Fechamento: ≤ 40m entre início e fim
- Cobertura: ≥ 60% dentro do tile

### Limites

- 3 ações territoriais por dia (usuário)
- 60 ações por dia (bandeira)

## Tecnologias

**Backend:**
- Kotlin + Spring Boot 3.2
- PostgreSQL + PostGIS
- Uber H3 (grid hexagonal)
- JWT Authentication

**Frontend:**
- Next.js 14 + TypeScript
- Mapbox GL JS
- Zustand (state)
- Vanilla CSS

## Licença

Proprietário - LigaRun © 2026
