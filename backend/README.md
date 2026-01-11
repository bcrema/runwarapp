# RunWar Backend

Backend em Kotlin/Spring Boot para o jogo de conquista territorial RunWar.

## Requisitos

- JDK 17+
- PostgreSQL 15+ com PostGIS
- Gradle 8.5+

## Setup Local

### 1. Banco de Dados

```bash
# Criar banco PostgreSQL com PostGIS
createdb runwar
psql runwar -c "CREATE EXTENSION postgis;"
```

### 2. Configuração

Crie um arquivo `.env` ou configure as variáveis de ambiente:

```bash
export DATABASE_URL=jdbc:postgresql://localhost:5432/runwar
export DATABASE_USER=postgres
export DATABASE_PASSWORD=postgres
export JWT_SECRET=sua-chave-secreta-256-bits-minimo
export CORS_ORIGINS=http://localhost:3000
```

### 3. Build e Run

```bash
# Build
./gradlew build

# Run
./gradlew bootRun

# Ou com Docker
docker build -t runwar-backend .
docker run -p 8080:8080 --env-file .env runwar-backend
```

## API Endpoints

### Auth (Público)
- `POST /api/auth/register` - Registrar novo usuário
- `POST /api/auth/login` - Login

### Users
- `GET /api/users/me` - Perfil do usuário atual
- `PUT /api/users/me` - Atualizar perfil

### Bandeiras
- `GET /api/bandeiras` - Listar todas
- `GET /api/bandeiras/{id}` - Detalhes
- `POST /api/bandeiras` - Criar bandeira
- `POST /api/bandeiras/{id}/join` - Entrar
- `POST /api/bandeiras/leave` - Sair

### Tiles (Público)
- `GET /api/tiles?minLat=&minLng=&maxLat=&maxLng=` - Tiles no viewport
- `GET /api/tiles/{id}` - Detalhes do tile
- `GET /api/tiles/stats` - Estatísticas do jogo

### Runs
- `POST /api/runs` - Submeter corrida (GPX)
- `POST /api/runs/coordinates` - Submeter via coordenadas
- `GET /api/runs` - Histórico de corridas
- `GET /api/runs/daily-status` - Status de ações diárias

### Rankings
- `GET /api/bandeiras/rankings` - Ranking de bandeiras

## Swagger UI

Acesse `http://localhost:8080/swagger-ui.html` para documentação interativa da API.

## Arquitetura

```
src/main/kotlin/com/runwar/
├── config/           # Configurações (Security, JWT, CORS)
├── domain/           # Entidades e lógica de domínio
│   ├── user/         # Usuários
│   ├── bandeira/     # Bandeiras/Times
│   ├── tile/         # Tiles hexagonais
│   ├── run/          # Corridas
│   └── territory/    # Ações territoriais
├── game/             # Lógica do jogo
│   ├── H3GridService # Grid hexagonal
│   ├── LoopValidator # Validação de loops
│   ├── ShieldMechanics # Mecânica de escudo
│   └── AntiFraudService # Detecção de fraude
├── geo/              # Processamento geoespacial
│   └── GpxParser     # Parser de GPX
└── notification/     # Notificações
```

## Parâmetros do Jogo

Todos configuráveis em `application.yml`:

| Parâmetro | Valor MVP |
|-----------|-----------|
| Raio do tile | ~250m (H3 res 8) |
| Loop mínimo | 1.2km, 7min |
| Fechamento loop | ≤40m |
| Cobertura mínima | 60% |
| Ataque | -35 escudo |
| Defesa | +20 escudo |
| Conquista | 100 escudo |
| Troca | 65 escudo |
| Cooldown | 18h |
| Em disputa | <70 escudo |
| Cap usuário | 3 ações/dia |
| Cap bandeira | 60 ações/dia |
