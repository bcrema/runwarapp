# Codex Agent Guide — frontend

## Escopo
- Next.js + TypeScript app em `frontend/`.
- Não alterar backend ou iOS aqui.

## Stack e comandos
- Node/npm: `npm install`, `npm run dev`, `npm run build`.
- API base: `NEXT_PUBLIC_API_URL` em `.env.local`.
- Mapbox: `NEXT_PUBLIC_MAPBOX_TOKEN` em `.env.local`.

## Padrões
- Seguir componentes e CSS modules existentes; evitar mudar rotas/app dir sem alinhamento.
- Prefira `rg` para buscas e manter nomes/prefixos atuais (tokens, storage keys).
- Evite introduzir dependências sem alinhamento.

## Testes
- Rodar `npm run lint`/`npm run test` se afetar lógica; mínimo: garantir build local (`npm run build`) se mexer em config.

## Segurança/segredos
- Não comitar `.env.local`; não expor tokens em código.

## Checklist rápida
- Variáveis de ambiente documentadas?
- Páginas ainda buildam (import paths corretos)?
