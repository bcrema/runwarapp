# LigaRun Frontend

Frontend Next.js para o jogo de conquista territorial LigaRun.

## Requisitos

- Node.js 18+
- npm ou yarn

## Setup

### 1. Instalar dependências

```bash
cd frontend
npm install
```

### 2. Configurar variáveis de ambiente

Crie um arquivo `.env.local`:

```bash
NEXT_PUBLIC_API_URL=http://localhost:8080
NEXT_PUBLIC_MAPBOX_TOKEN=seu_token_mapbox
```

Para obter um token do Mapbox:
1. Acesse https://www.mapbox.com/
2. Crie uma conta gratuita
3. Copie seu Access Token

### 3. Executar

```bash
npm run dev
```

Acesse http://localhost:3000

## Estrutura

```
src/
├── app/
│   ├── (auth)/           # Páginas de autenticação
│   │   ├── login/
│   │   └── register/
│   ├── (game)/           # Páginas do jogo (protegidas)
│   │   ├── map/          # Mapa principal
│   │   ├── run/          # Registrar corrida
│   │   ├── profile/      # Perfil
│   │   ├── bandeira/     # Bandeiras
│   │   └── rankings/     # Rankings
│   ├── layout.tsx
│   └── page.tsx          # Landing page
├── components/
│   ├── map/
│   │   └── HexMap.tsx    # Mapa com tiles hexagonais
│   ├── run/
│   └── ui/
├── lib/
│   ├── api.ts            # Cliente API
│   └── auth.ts           # Store de autenticação
└── styles/
    └── globals.css       # Design system
```

## Funcionalidades

### Landing Page
- Apresentação do jogo
- Links para login/registro

### Mapa
- Visualização de tiles hexagonais (Mapbox + H3)
- Cores por dono/estado
- Popup com detalhes do tile
- Indicadores de disputa

### Registrar Corrida
- Upload de arquivo GPX
- Gravação GPS em tempo real (web)
- Feedback de validação do loop
- Resultado da ação territorial

### Perfil
- Estatísticas do usuário
- Tiles conquistados
- Badges

### Bandeiras
- Listar/buscar bandeiras
- Criar bandeira
- Entrar/sair de bandeira
- Ver membros

### Rankings
- Ranking solo (semanal/temporada)
- Ranking bandeiras

## Design System

O CSS usa variáveis para um tema dark moderno:

- **Cores**: Paleta roxa/índigo com acentos para ações do jogo
- **Tipografia**: Inter (Google Fonts)
- **Componentes**: Cards, buttons, badges, inputs
- **Animações**: Transições suaves e micro-animações

## Deploy

```bash
npm run build
npm start

# Ou com Vercel
npx vercel
```

## Ambiente de Produção

Variáveis necessárias:
- `NEXT_PUBLIC_API_URL`: URL do backend em produção
- `NEXT_PUBLIC_MAPBOX_TOKEN`: Token do Mapbox
