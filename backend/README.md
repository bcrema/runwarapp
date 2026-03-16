# LigaRun Backend

Backend em Kotlin/Spring Boot para o jogo de conquista territorial LigaRun.

## Requisitos

- JDK 25
- PostgreSQL 15+ com PostGIS
- Gradle 9.1+

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
export JWT_REFRESH_EXPIRATION=2592000000
export JWT_EXPIRATION=900000
export JWT_SOCIAL_LINK_EXPIRATION=600000
export CORS_ORIGINS=http://localhost:3000
export AUTH_SOCIAL_GOOGLE_CLIENT_IDS=google-web-client-id,google-ios-client-id
export AUTH_SOCIAL_APPLE_CLIENT_IDS=com.runwar.ligarun,com.runwar.web.signin
export RUNWAR_SEED_ENABLED=true # opcional: insere dados mock para testes
```

### 3. Build e Run

O Gradle está configurado com configuration cache habilitado por padrão para acelerar execuções repetidas.

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
- `POST /api/auth/signup` - Registrar novo usuário
- `POST /api/auth/login` - Login
- `POST /api/auth/social/exchange` - Exchange de `Google`/`Apple` por sessão própria
- `POST /api/auth/social/link/confirm` - Vincular login social a conta existente
- `POST /api/auth/refresh` - Renovar access token
- `POST /api/auth/logout` - Logout (revoga refresh token)

### Users
- `GET /api/users/me` - Perfil do usuário atual
- `PUT /api/users/me` - Atualizar perfil
- `GET /api/users/rankings?scope=season` - Ranking solo da temporada ativa
- `GET /api/users/me/badges` - Badges do usuário com progresso parcial
- `GET /api/users/me/missions/active` - Missões ativas da semana corrente

### Bandeiras
- `GET /api/bandeiras` - Listar todas
- `GET /api/bandeiras/{id}` - Detalhes
- `GET /api/bandeiras/{id}/members` - Membros da bandeira
- `GET /api/bandeiras/{id}/presence?period=week` - Presença semanal agregada da bandeira
- `POST /api/bandeiras` - Criar bandeira
- `POST /api/bandeiras/{id}/join` - Entrar
- `POST /api/bandeiras/leave` - Sair

### Quadras (Público)
- `GET /api/quadras?minLat=&minLng=&maxLat=&maxLng=` - Quadras no viewport
- `GET /api/quadras/{id}` - Detalhes da quadra
- `GET /api/quadras/disputed` - Quadras em disputa
- `GET /api/quadras/stats` - Estatísticas do jogo

### Runs
- `POST /api/runs` - Submeter corrida (GPX)
- `POST /api/runs/coordinates` - Submeter via coordenadas
- `GET /api/runs` - Histórico de corridas
- `GET /api/runs/daily-status` - Status de ações diárias

### Contrato iOS v2 (quadras)

- `POST /api/runs/coordinates` aceita:
  - `coordinates`, `timestamps`, `mode` (`COMPETITIVE`/`TRAINING`) e `targetQuadraId` opcional;
  - `timestamps` em **epoch seconds** e **epoch milliseconds** (normalização automática server-side).
- `mode=TRAINING` não executa ação territorial e não consome ação diária.
- Resposta de submissão (`POST /api/runs` e `POST /api/runs/coordinates`) retorna:
  - `run.distance` e `run.loopDistance` em **km** (compatibilidade iOS atual);
  - `run.distanceMeters` e `run.loopDistanceMeters` em **metros** (referência canônica);
  - `run.targetQuadraId`;
  - `loopValidation` no formato `{ isValid, distance, duration, closingDistance, quadrasCovered, primaryQuadra, primaryQuadraCoverage, fraudFlags, failureReasons }`;
  - `territoryResult` quando houver ação territorial processada;
  - `territoryResult.quadraId` e `turnResult.quadraId`;
  - `dailyActionsRemaining` derivado de `turnResult.capsRemaining.userActionsRemaining`.
- `GET /api/users/me` e `AuthResponse.user`:
  - `totalDistance` em **km**;
  - `totalDistanceMeters` em **metros**.
- `GET /api/runs` e `GET /api/runs/{id}`:
  - `distance` e `loopDistance` em **km**;
  - `distanceMeters` e `loopDistanceMeters` em **metros**.

### Rankings
- `GET /api/bandeiras/rankings` - Ranking de bandeiras

### Notifications
- `GET /api/notifications?cursor=&limit=20` - Inbox paginada do usuário autenticado
- `POST /api/devices/push-token` - Registrar ou atualizar token push por device

## Swagger UI

Acesse `http://localhost:8080/swagger-ui.html` para documentação interativa da API.

## OpenAPI exportado

O OpenAPI exportado fica versionado em `backend/openapi/openapi.json` para uso no app.

Para atualizar o arquivo, execute:

```bash
./backend/scripts/export-openapi.sh
```

## Auth social

- Provedores suportados hoje: `google` e `apple`.
- O backend valida `issuer`, `audience` e assinatura do `idToken` via JWKS oficial do provedor antes de emitir `accessToken` e `refreshToken` próprios.
- `POST /api/auth/social/exchange` aceita:
  - `provider`
  - `idToken`
  - `authorizationCode` opcional
  - `nonce` opcional
  - `emailHint`, `givenName`, `familyName` e `avatarUrl` opcionais
- Quando o email verificado do provedor já pertence a uma conta não vinculada, o endpoint responde `409 LINK_REQUIRED` com `linkToken`, `provider` e `emailMasked`.
- `POST /api/auth/social/link/confirm` aceita `linkToken`, `email` e `password`; no sucesso, vincula a identidade social e retorna `AuthResponse`.
- Usuários criados via login social recebem `username` automático e podem editar depois pelo fluxo normal de perfil.
## Contratos GDS v3

### Ranking solo

- `GET /api/users/rankings?scope=season`
- Retorna a temporada ativa, `generatedAt`, `entries[]` ordenadas por `totalPoints DESC` e `currentUserEntry` quando o usuário autenticado aparece no ranking.
- O payload já inclui `username`, `avatarUrl`, `bandeiraId`, `bandeiraName`, `dailyPoints`, `clusterBonus` e `totalPoints`, sem necessidade de chamadas extras.

### Presença semanal de bandeira

- `GET /api/bandeiras/{id}/presence?period=week`
- A janela semanal usa timezone `America/Sao_Paulo`, com início na segunda-feira `00:00` e fim no domingo `23:59:59.999`.
- `summary` consolida membros ativos, total de membros, corridas e distância; `members[]` sempre inclui membros sem atividade com `presenceState=INACTIVE`.

### Notificações e push token

- `GET /api/notifications?cursor=<opaque>&limit=20`
- O cursor é opaco e pagina por `createdAt DESC, id DESC`.
- `POST /api/devices/push-token` é idempotente por par `userId + deviceId`; reenviar o mesmo device atualiza `token`, `platform`, `appVersion` e `updatedAt`.

### Badges e missões

- `GET /api/users/me/badges`
- Cada badge retorna `earnedAt` e `progress` com `criteriaType`, `currentValue`, `targetValue`, `unit` e `completed`.
- Critérios suportados hoje:
  - `conquest`: usa `users.total_quadras_conquered`
  - `attack`: usa quantidade de `territory_actions` com `action_type = ATTACK`
  - `defense_dispute`: usa defesas com `shield_before < 70`
  - `distance`: usa `users.total_distance` em metros
  - `streak`: usa a melhor sequência de dias consecutivos com corrida no timezone `America/Sao_Paulo`
- `GET /api/users/me/missions/active` retorna apenas as missões da semana corrente (`weekStart` da segunda-feira local) e cobre progresso parcial e empty state.

## Dados mock (opcional)

Se `RUNWAR_SEED_ENABLED=true`, o backend cria alguns usuários/bandeiras/tiles para testes na primeira execução:

- `alpha.admin+seed@runwar.local` / `password123`
- `beta.admin+seed@runwar.local` / `password123`
- `alice+seed@runwar.local` / `password123`

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

## Flags de validação de loop (server-authoritative)

Para pilotos sem deploy, é possível alterar os parâmetros do LoopValidator via arquivo local e
recarregamento automático por modificação do arquivo.

Configure o caminho do arquivo e a cidade padrão:

```yaml
runwar:
  loop-validation-flags-path: /app/config/loop-validation-flags.json
  loop-validation-default-city: curitiba
```

Observação: `loop-validation-default-city` é usado apenas para selecionar quais overrides de flags
serão aplicados a partir da chave correspondente em `byCity` no arquivo JSON. Ele **não** altera a
área do jogo nem os limites geográficos usados pelo validador, que atualmente permanecem fixos em
Curitiba (via configuração `runwar.game.curitiba`).
Formato do arquivo (`loop-validation-flags.json`):

```json
{
  "defaults": {
    "minLoopDistanceKm": 1.2,
    "minLoopDurationMin": 7,
    "maxClosureMeters": 40,
    "minCoveragePct": 0.6
  },
  "byCity": {
    "curitiba": {
      "minLoopDistanceKm": 1.2,
      "minLoopDurationMin": 7,
      "maxClosureMeters": 40,
      "minCoveragePct": 0.6
    }
  },
  "byBandeira": {
    "alpha": {
      "minLoopDistanceKm": 1.5,
      "minLoopDurationMin": 8,
      "maxClosureMeters": 30,
      "minCoveragePct": 0.7
    }
  }
}
```
